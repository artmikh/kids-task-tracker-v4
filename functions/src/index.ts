import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

const db = admin.firestore();

// ============================================
// 1. НАЧИСЛЕНИЕ ЗВЁЗД при выполнении задачи
// ============================================
export const awardStarsOnTaskComplete = functions.firestore
  .document('tasks/{taskId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // --- Начисление: переход в 'done' ---
    if (before.status !== 'done' && after.status === 'done') {
      const childId = after.childId;
      const rewardStars = after.rewardStars || 0;

      if (childId && rewardStars > 0) {
        // Начисляем звёзды
        await db.collection('users').doc(childId).update({
          stars: admin.firestore.FieldValue.increment(rewardStars),
        });

        // Записываем транзакцию в историю
        await db.collection('transactions').add({
          userId: childId,
          type: 'earned',
          amount: rewardStars,
          taskId: context.params.taskId,
          description: `Награда за: ${after.title}`,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log(`✅ Начислено ${rewardStars} звёзд ребенку ${childId}`);
      }
    }

    // --- Списание: возврат из 'done' ---
    if (before.status === 'done' && after.status !== 'done') {
      const childId = before.childId;
      const rewardStars = before.rewardStars || 0;

      if (childId && rewardStars > 0) {
        // Списываем звёзды
        await db.collection('users').doc(childId).update({
          stars: admin.firestore.FieldValue.increment(-rewardStars),
        });

        // Записываем транзакцию
        await db.collection('transactions').add({
          userId: childId,
          type: 'revoked',
          amount: -rewardStars,
          taskId: context.params.taskId,
          description: `Отмена награды: ${before.title}`,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log(`↩️ Списано ${rewardStars} звёзд у ребенка ${childId}`);
      }
    }
  });

// ============================================
// 2. ПОКУПКА НАГРАДЫ ребёнком
// ============================================
export const purchaseReward = functions.https.onCall(async (data, context) => {
  // Проверка авторизации
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Необходима авторизация');
  }

  const { rewardId } = data;
  if (!rewardId || typeof rewardId !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', 'Нужен rewardId');
  }

  const uid = context.auth.uid;

  // Получаем награду
  const rewardDoc = await db.collection('rewards').doc(rewardId).get();
  if (!rewardDoc.exists) {
    throw new functions.https.HttpsError('not-found', 'Награда не найдена');
  }
  const reward = rewardDoc.data()!;

  // Получаем профиль ребёнка
  const userDoc = await db.collection('users').doc(uid).get();
  if (!userDoc.exists) {
    throw new functions.https.HttpsError('not-found', 'Профиль не найден');
  }
  const user = userDoc.data()!;

  // Проверяем роль
  if (user.role !== 'child') {
    throw new functions.https.HttpsError('permission-denied', 'Только дети могут покупать награды');
  }

  // Проверяем достаточность баланса
  const cost = reward.costInStars || 0;
  if (cost <= 0) {
    throw new functions.https.HttpsError('invalid-argument', 'Награда бесплатная — обращайтесь к родителю');
  }

  if ((user.stars || 0) < cost) {
    throw new functions.https.HttpsError('failed-precondition', 
      `Недостаточно звёзд. Нужно: ${cost}, у вас: ${user.stars || 0}`);
  }

  // Транзакция: списываем звёзды + создаём запись о покупке
  await db.runTransaction(async (transaction) => {
    // Перечитываем документ для актуальности
    const freshUserDoc = await transaction.get(db.collection('users').doc(uid));
    const freshStars = freshUserDoc.data()?.stars || 0;

    if (freshStars < cost) {
      throw new functions.https.HttpsError('failed-precondition', 'Недостаточно звёзд');
    }

    // Списываем звёзды
    transaction.update(db.collection('users').doc(uid), {
      stars: admin.firestore.FieldValue.increment(-cost),
    });

    // Записываем покупку
    transaction.create(db.collection('purchased_rewards').doc(), {
      childId: uid,
      rewardId: rewardId,
      rewardTitle: reward.title,
      rewardType: reward.type,
      costInStars: cost,
      parentId: reward.parentId,
      purchasedAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'pending', // pending → parent подтверждает выдачу
    });

    // Записываем транзакцию
    transaction.create(db.collection('transactions').doc(), {
      userId: uid,
      type: 'spent',
      amount: -cost,
      rewardId: rewardId,
      description: `Покупка: ${reward.title}`,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  return { success: true, message: `Награда "${reward.title}" куплена за ${cost} звёзд!` };
});