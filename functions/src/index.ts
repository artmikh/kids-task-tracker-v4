import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { onCall } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

admin.initializeApp();

const db = admin.firestore();

// ============================================
// 1. НАЧИСЛЕНИЕ ЗВЁЗД при выполнении задачи
// ============================================
export const awardStarsOnTaskComplete = onDocumentUpdated(
  {
    document: 'tasks/{taskId}',
    region: 'europe-west1', // укажи свой регион
  },
  async (event) => {
    if (!event.data) return;

    const before = event.data.before.data();
    const after = event.data.after.data();

    // --- Начисление: переход в 'done' ---
    if (before.status !== 'done' && after.status === 'done') {
      const childId = after.childId;
      const rewardStars = after.rewardStars || 0;

      if (childId && rewardStars > 0) {
        await db.collection('users').doc(childId).update({
          stars: admin.firestore.FieldValue.increment(rewardStars),
        });

        await db.collection('transactions').add({
          userId: childId,
          type: 'earned',
          amount: rewardStars,
          taskId: event.params.taskId,
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
        await db.collection('users').doc(childId).update({
          stars: admin.firestore.FieldValue.increment(-rewardStars),
        });

        await db.collection('transactions').add({
          userId: childId,
          type: 'revoked',
          amount: -rewardStars,
          taskId: event.params.taskId,
          description: `Отмена награды: ${before.title}`,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log(`↩️ Списано ${rewardStars} звёзд у ребенка ${childId}`);
      }
    }
  }
);

// ============================================
// 2. ПОКУПКА НАГРАДЫ ребёнком
// ============================================
export const purchaseReward = onCall(
  {
    region: 'europe-west1', // укажи свой регион
  },
  async (request) => {
    if (!request.auth) {
      throw new Error('Unauthenticated: Необходима авторизация');
    }

    const { rewardId } = request.data;
    if (!rewardId || typeof rewardId !== 'string') {
      throw new Error('Invalid argument: Нужен rewardId');
    }

    const uid = request.auth.uid;

    const rewardDoc = await db.collection('rewards').doc(rewardId).get();
    if (!rewardDoc.exists) {
      throw new Error('Not found: Награда не найдена');
    }
    const reward = rewardDoc.data()!;

    const userDoc = await db.collection('users').doc(uid).get();
    if (!userDoc.exists) {
      throw new Error('Not found: Профиль не найден');
    }
    const user = userDoc.data()!;

    if (user.role !== 'child') {
      throw new Error('Permission denied: Только дети могут покупать награды');
    }

    const cost = reward.costInStars || 0;
    if (cost <= 0) {
      throw new Error('Invalid argument: Награда бесплатная');
    }

    if ((user.stars || 0) < cost) {
      throw new Error(
        `Failed precondition: Недостаточно звёзд. Нужно: ${cost}, у вас: ${user.stars || 0}`
      );
    }

    await db.runTransaction(async (transaction) => {
      const freshUserDoc = await transaction.get(db.collection('users').doc(uid));
      const freshStars = freshUserDoc.data()?.stars || 0;

      if (freshStars < cost) {
        throw new Error('Failed precondition: Недостаточно звёзд');
      }

      transaction.update(db.collection('users').doc(uid), {
        stars: admin.firestore.FieldValue.increment(-cost),
      });

      transaction.create(db.collection('purchased_rewards').doc(), {
        childId: uid,
        rewardId: rewardId,
        rewardTitle: reward.title,
        rewardType: reward.type,
        costInStars: cost,
        parentId: reward.parentId,
        purchasedAt: admin.firestore.FieldValue.serverTimestamp(),
        status: 'pending',
      });

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
  }
);