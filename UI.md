<!-- Parent: Create Task -->
<!DOCTYPE html>

<html lang="en"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<title>Create New Task</title>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<script id="tailwind-config">
        tailwind.config = {
            darkMode: "class",
            theme: {
                extend: {
                    colors: {
                        "primary": "#f48c25",
                        "background-light": "#f8f7f5",
                        "background-dark": "#221910",
                    },
                    fontFamily: {
                        "display": ["Plus Jakarta Sans"]
                    },
                    borderRadius: {"DEFAULT": "0.5rem", "lg": "1rem", "xl": "1.5rem", "full": "9999px"},
                },
            },
        }
    </script>
<style>
    body {
      min-height: max(884px, 100dvh);
    }
  </style>
  </head>
<body class="bg-background-light dark:bg-background-dark font-display antialiased text-slate-900 dark:text-slate-100">
<div class="relative flex min-h-screen w-full flex-col max-w-md mx-auto bg-background-light dark:bg-background-dark overflow-x-hidden">
<!-- Top Navigation -->
<div class="flex items-center p-4 pb-2 justify-between">
<div class="text-primary flex size-12 shrink-0 items-center justify-center cursor-pointer hover:bg-primary/10 rounded-full transition-colors">
<span class="material-symbols-outlined">arrow_back</span>
</div>
<h2 class="text-slate-900 dark:text-slate-100 text-lg font-bold leading-tight tracking-tight flex-1 text-center pr-12">Create New Task</h2>
</div>
<!-- Task Image Illustration -->
<div class="px-4 py-4">
<div class="w-full h-40 rounded-xl bg-gradient-to-br from-primary/20 to-primary/5 flex items-center justify-center border-2 border-dashed border-primary/20 relative overflow-hidden">
<div class="flex flex-col items-center gap-2 z-10">
<span class="material-symbols-outlined text-primary text-5xl">task_alt</span>
<p class="text-primary font-medium">Add a task icon</p>
</div>
<div class="absolute inset-0 opacity-10 bg-[radial-gradient(circle_at_center,_var(--tw-gradient-stops))] from-primary via-transparent to-transparent"></div>
</div>
</div>
<!-- Form Content -->
<div class="flex flex-col gap-6 px-4 py-4">
<!-- Task Title Input -->
<label class="flex flex-col gap-2">
<p class="text-slate-900 dark:text-slate-100 text-base font-semibold leading-normal">Task Title</p>
<input class="form-input flex w-full rounded-xl border-primary/20 bg-white dark:bg-slate-800 text-slate-900 dark:text-slate-100 focus:border-primary focus:ring-1 focus:ring-primary h-14 placeholder:text-slate-400 p-4 text-base font-normal" placeholder="e.g., Clean your room" type="text"/>
</label>
<!-- Category Selection -->
<div class="flex flex-col gap-3">
<h3 class="text-slate-900 dark:text-slate-100 text-base font-semibold leading-tight">Category</h3>
<div class="flex gap-3 flex-wrap">
<button class="flex h-10 items-center justify-center gap-x-2 rounded-full bg-primary text-white px-5 shadow-sm shadow-primary/20 transition-all">
<span class="material-symbols-outlined text-lg">mop</span>
<span class="text-sm font-medium">Chores</span>
</button>
<button class="flex h-10 items-center justify-center gap-x-2 rounded-full bg-primary/10 dark:bg-primary/20 text-slate-700 dark:text-slate-200 px-5 hover:bg-primary/20 transition-all">
<span class="material-symbols-outlined text-lg">menu_book</span>
<span class="text-sm font-medium">Homework</span>
</button>
<button class="flex h-10 items-center justify-center gap-x-2 rounded-full bg-primary/10 dark:bg-primary/20 text-slate-700 dark:text-slate-200 px-5 hover:bg-primary/20 transition-all">
<span class="material-symbols-outlined text-lg">favorite</span>
<span class="text-sm font-medium">Health</span>
</button>
<button class="flex h-10 items-center justify-center gap-x-2 rounded-full bg-slate-100 dark:bg-slate-700 text-slate-500 px-4">
<span class="material-symbols-outlined text-lg">add</span>
</button>
</div>
</div>
<!-- Reward Points Slider -->
<div class="flex flex-col gap-4 py-2">
<div class="flex items-center justify-between">
<p class="text-slate-900 dark:text-slate-100 text-base font-semibold leading-normal">Reward Points</p>
<div class="flex items-center gap-1 bg-primary/10 px-3 py-1 rounded-full">
<span class="material-symbols-outlined text-primary text-sm fill-1">stars</span>
<span class="text-primary font-bold text-lg">50</span>
</div>
</div>
<div class="relative w-full h-8 flex items-center">
<div class="h-2 w-full bg-primary/20 rounded-full overflow-hidden">
<div class="h-full bg-primary" style="width: 45%;"></div>
</div>
<div class="absolute left-[45%] top-1/2 -translate-y-1/2 -translate-x-1/2 size-6 bg-white border-4 border-primary rounded-full shadow-md cursor-pointer"></div>
</div>
<div class="flex justify-between text-xs text-slate-400 font-medium px-1">
<span>10 pts</span>
<span>50 pts</span>
<span>100 pts</span>
</div>
</div>
<!-- Additional Options -->
<div class="flex flex-col gap-4 pt-2">
<div class="flex items-center justify-between p-4 bg-white dark:bg-slate-800 rounded-xl border border-primary/10">
<div class="flex items-center gap-3">
<div class="size-10 bg-blue-100 dark:bg-blue-900/30 text-blue-600 rounded-lg flex items-center justify-center">
<span class="material-symbols-outlined">calendar_today</span>
</div>
<div>
<p class="text-sm font-bold">Due Date</p>
<p class="text-xs text-slate-500">Today, 6:00 PM</p>
</div>
</div>
<span class="material-symbols-outlined text-slate-400">chevron_right</span>
</div>
<div class="flex items-center justify-between p-4 bg-white dark:bg-slate-800 rounded-xl border border-primary/10">
<div class="flex items-center gap-3">
<div class="size-10 bg-purple-100 dark:bg-purple-900/30 text-purple-600 rounded-lg flex items-center justify-center">
<span class="material-symbols-outlined">repeat</span>
</div>
<div>
<p class="text-sm font-bold">Repeat</p>
<p class="text-xs text-slate-500">No repeat</p>
</div>
</div>
<span class="material-symbols-outlined text-slate-400">chevron_right</span>
</div>
</div>
</div>
<!-- Sticky Bottom Button -->
<div class="mt-auto p-4 pb-8">
<button class="w-full bg-primary hover:bg-primary/90 text-white font-bold py-4 rounded-xl shadow-lg shadow-primary/30 transition-all flex items-center justify-center gap-2">
<span>Create Task</span>
<span class="material-symbols-outlined">arrow_forward</span>
</button>
</div>
</div>
</body></html>

<!-- Child: Rewards & Badges -->
<!DOCTYPE html>

<html lang="en"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<title>My Rewards &amp; Achievements</title>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<script id="tailwind-config">
        tailwind.config = {
            darkMode: "class",
            theme: {
                extend: {
                    colors: {
                        "primary": "#f48c25",
                        "background-light": "#f8f7f5",
                        "background-dark": "#221910",
                    },
                    fontFamily: {
                        "display": ["Plus Jakarta Sans"]
                    },
                    borderRadius: {"DEFAULT": "0.5rem", "lg": "1rem", "xl": "1.5rem", "full": "9999px"},
                },
            },
        }
    </script>
<style>
    body {
      min-height: max(884px, 100dvh);
    }
  </style>
  </head>
<body class="bg-background-light dark:bg-background-dark font-display text-slate-900 dark:text-slate-100 min-h-screen">
<div class="relative flex h-auto min-h-screen w-full flex-col bg-background-light dark:bg-background-dark overflow-x-hidden pb-24">
<div class="flex items-center bg-background-light dark:bg-background-dark p-4 pb-2 justify-between sticky top-0 z-10 border-b border-primary/10">
<div class="text-primary flex size-12 shrink-0 items-center justify-center">
<span class="material-symbols-outlined text-3xl">arrow_back</span>
</div>
<h2 class="text-slate-900 dark:text-slate-100 text-xl font-bold leading-tight tracking-[-0.015em] flex-1 text-center">Trophy Room</h2>
<div class="flex w-12 items-center justify-end">
<button class="flex items-center justify-center rounded-xl h-10 w-10 bg-primary/10 text-primary">
<span class="material-symbols-outlined fill-1">settings</span>
</button>
</div>
</div>
<div class="p-4">
<div class="flex flex-col gap-2 rounded-xl p-6 bg-gradient-to-br from-primary to-primary/80 text-white shadow-lg shadow-primary/20 relative overflow-hidden">
<div class="absolute -right-4 -top-4 opacity-20">
<span class="material-symbols-outlined text-[120px] fill-1">stars</span>
</div>
<div class="relative z-10">
<p class="text-white/90 text-sm font-medium uppercase tracking-wider">Total Stars Earned</p>
<div class="flex items-baseline gap-2 mt-1">
<p class="text-white text-5xl font-bold leading-tight">1,250</p>
<span class="material-symbols-outlined text-3xl fill-1">grade</span>
</div>
<div class="flex items-center gap-1 mt-4 bg-white/20 w-fit px-3 py-1 rounded-full backdrop-blur-sm">
<span class="material-symbols-outlined text-sm">trending_up</span>
<p class="text-sm font-bold">+50 this week</p>
</div>
</div>
</div>
</div>
<div class="px-4 py-2">
<div class="flex items-center justify-between mb-4">
<h2 class="text-slate-900 dark:text-slate-100 text-[22px] font-bold leading-tight tracking-[-0.015em]">Badges Earned</h2>
<span class="text-primary text-sm font-bold">View All</span>
</div>
<div class="flex w-full overflow-x-auto no-scrollbar gap-5 pb-2">
<div class="flex flex-col items-center gap-2 min-w-[80px]">
<div class="w-16 h-16 bg-gradient-to-tr from-yellow-400 to-orange-500 rounded-full flex items-center justify-center shadow-md border-4 border-white dark:border-slate-800">
<span class="material-symbols-outlined text-white text-3xl fill-1">auto_awesome</span>
</div>
<p class="text-slate-700 dark:text-slate-300 text-xs font-bold text-center">Super Helper</p>
</div>
<div class="flex flex-col items-center gap-2 min-w-[80px]">
<div class="w-16 h-16 bg-gradient-to-tr from-blue-400 to-indigo-500 rounded-full flex items-center justify-center shadow-md border-4 border-white dark:border-slate-800">
<span class="material-symbols-outlined text-white text-3xl fill-1">functions</span>
</div>
<p class="text-slate-700 dark:text-slate-300 text-xs font-bold text-center">Math Whiz</p>
</div>
<div class="flex flex-col items-center gap-2 min-w-[80px]">
<div class="w-16 h-16 bg-gradient-to-tr from-green-400 to-emerald-500 rounded-full flex items-center justify-center shadow-md border-4 border-white dark:border-slate-800">
<span class="material-symbols-outlined text-white text-3xl fill-1">cleaning_services</span>
</div>
<p class="text-slate-700 dark:text-slate-300 text-xs font-bold text-center">Clean Room</p>
</div>
<div class="flex flex-col items-center gap-2 min-w-[80px]">
<div class="w-16 h-16 bg-gradient-to-tr from-purple-400 to-pink-500 rounded-full flex items-center justify-center shadow-md border-4 border-white dark:border-slate-800">
<span class="material-symbols-outlined text-white text-3xl fill-1">alarm_on</span>
</div>
<p class="text-slate-700 dark:text-slate-300 text-xs font-bold text-center">Early Bird</p>
</div>
<div class="flex flex-col items-center gap-2 min-w-[80px] opacity-40 grayscale">
<div class="w-16 h-16 bg-slate-200 dark:bg-slate-700 rounded-full flex items-center justify-center border-4 border-white dark:border-slate-800 border-dashed">
<span class="material-symbols-outlined text-slate-400 text-3xl">lock</span>
</div>
<p class="text-slate-700 dark:text-slate-300 text-xs font-bold text-center">Book Worm</p>
</div>
</div>
</div>
<div class="px-4 py-6">
<h2 class="text-slate-900 dark:text-slate-100 text-[22px] font-bold leading-tight tracking-[-0.015em] mb-4">Available Rewards</h2>
<div class="grid grid-cols-2 gap-4">
<div class="bg-white dark:bg-background-dark border border-primary/10 rounded-xl p-4 flex flex-col gap-3 shadow-sm">
<div class="w-full aspect-video rounded-lg overflow-hidden relative">
<img class="w-full h-full object-cover" data-alt="Gaming setup with colorful lights" src="https://lh3.googleusercontent.com/aida-public/AB6AXuC7LrVI6qhELFSLkl-n_mGKyEf36wEM95v6wjpx6mKk2FNeCsdJ3yyJP-yriNdEvPoiUu4tcf4zH51mG1afCkvgQEGKhXZc6GBaXy8eEoY--E4xQ6LDW-xKcA0sWyDnIpnqerLC1YFWAnh1qDWonej-Z-zCVHEKPTa42xbEdYv_cOoVN8wzeo-RJa-MzdhLznKQUBVc4lQarCVWSVN1N5sePqVb9rxvN7GZa6pEpIVRdUH173jC3NzjsnwNneUYTxQfMAZ4cGv0o7i4"/>
<div class="absolute top-2 right-2 bg-primary text-white px-2 py-1 rounded-lg text-xs font-bold">30 MIN</div>
</div>
<div>
<h3 class="font-bold text-slate-900 dark:text-slate-100">Gaming Session</h3>
<p class="text-xs text-slate-500 dark:text-slate-400">Extra playtime on console</p>
</div>
<div class="flex items-center justify-between mt-auto">
<div class="flex items-center gap-1 text-primary">
<span class="material-symbols-outlined text-sm fill-1">grade</span>
<span class="font-bold">200</span>
</div>
<button class="bg-primary hover:bg-primary/90 text-white text-xs font-bold py-2 px-4 rounded-full">Redeem</button>
</div>
</div>
<div class="bg-white dark:bg-background-dark border border-primary/10 rounded-xl p-4 flex flex-col gap-3 shadow-sm">
<div class="w-full aspect-video rounded-lg overflow-hidden relative">
<img class="w-full h-full object-cover" data-alt="Delicious colorful ice cream scoops" src="https://lh3.googleusercontent.com/aida-public/AB6AXuBG9QrexTAc1kT_zqdg-iUMz_7HtkQ-zt5P5czZKxO2UvnRpyZ_wwRBNYPpzRjhqBmU2clbB9x6mohRt2gu3yfovsNXrIBRnBPHYobOBzrCnXOYGag_KoAjBG6h1lYA6S5z4jx2_pRqTYBHPKe97q-tXMz39vUOdQaPcBkuh5Sz1FQ8i2lwTRPR5gX_8g21_zZzuufgbEUMnfiZ4CEuYmq1diicudzrOUK0ILNiriKLpgeTVZx-Utc8_onR4RL-kP3Fb7etvNPGxFmF"/>
</div>
<div>
<h3 class="font-bold text-slate-900 dark:text-slate-100">Ice Cream Trip</h3>
<p class="text-xs text-slate-500 dark:text-slate-400">Visit your favorite shop</p>
</div>
<div class="flex items-center justify-between mt-auto">
<div class="flex items-center gap-1 text-primary">
<span class="material-symbols-outlined text-sm fill-1">grade</span>
<span class="font-bold">500</span>
</div>
<button class="bg-primary hover:bg-primary/90 text-white text-xs font-bold py-2 px-4 rounded-full">Redeem</button>
</div>
</div>
<div class="bg-white dark:bg-background-dark border border-primary/10 rounded-xl p-4 flex flex-col gap-3 shadow-sm">
<div class="w-full aspect-video rounded-lg overflow-hidden relative">
<img class="w-full h-full object-cover" data-alt="Movie theater popcorn and seats" src="https://lh3.googleusercontent.com/aida-public/AB6AXuCxJpd-SLk6NqL2jN8amQpIyTZa7hB-cPJl5V6KcRKHyH0ta78rOaVUgsvdZX62iZRgTIEgOIkDtvrxmEcDumkhWGHQrOuxOU5nMZHFc4s4rms336F2u7Ceu_griCN7rI-IxTA0ksM2CYqLVGibJPYL5AEFMKjBRzqE3sd1-9A7vCRP0CPv2xDRF7g6JyGz-G5_IBjTIlX_p4HnG5gfjp-7abwtXD1bcLMwpbYxpopkgz_xmM2AO6YFEzUOkFqcS0Eg3EXdc0IlCWUE"/>
</div>
<div>
<h3 class="font-bold text-slate-900 dark:text-slate-100">Movie Night</h3>
<p class="text-xs text-slate-500 dark:text-slate-400">Pick any movie to watch</p>
</div>
<div class="flex items-center justify-between mt-auto">
<div class="flex items-center gap-1 text-primary">
<span class="material-symbols-outlined text-sm fill-1">grade</span>
<span class="font-bold">350</span>
</div>
<button class="bg-primary hover:bg-primary/90 text-white text-xs font-bold py-2 px-4 rounded-full">Redeem</button>
</div>
</div>
<div class="bg-white dark:bg-background-dark border border-primary/10 rounded-xl p-4 flex flex-col gap-3 shadow-sm opacity-60">
<div class="w-full aspect-video rounded-lg overflow-hidden relative">
<img class="w-full h-full object-cover" data-alt="Toy store shelves full of toys" src="https://lh3.googleusercontent.com/aida-public/AB6AXuDZziHX8hAoH-Q_HmsaPK3RAmR4JXIAydENSuv4HSpspYmWzzIGaI9xG5Fy994SccUyCif5h79IYuZiq-0F-nGstdcDkKGB6PMEV31y9sOdZj5JwjMY54umcPOZwXsq3OYAD7qJTqCEJfAsiPeXQI_EX-YX8Nph0rdjWWfY7-0nve_NBb04JvQxh8b0_kKyfVf-az5lPHb09gjEuqJpZ6P5EqQrqXKPnA-F5G0bmFsO9VXEFd9YV8ZVZBE_dEA1flkkVkqsIXuKSnfB"/>
</div>
<div>
<h3 class="font-bold text-slate-900 dark:text-slate-100">New Toy</h3>
<p class="text-xs text-slate-500 dark:text-slate-400">A small surprise toy</p>
</div>
<div class="flex items-center justify-between mt-auto">
<div class="flex items-center gap-1 text-slate-500">
<span class="material-symbols-outlined text-sm fill-1">grade</span>
<span class="font-bold">1500</span>
</div>
<button class="bg-slate-200 dark:bg-slate-700 text-slate-500 text-xs font-bold py-2 px-4 rounded-full cursor-not-allowed">Locked</button>
</div>
</div>
</div>
</div>
<div class="fixed bottom-0 left-0 right-0 z-20">
<div class="flex gap-2 border-t border-primary/10 bg-background-light dark:bg-background-dark px-4 pb-6 pt-2 shadow-2xl">
<a class="flex flex-1 flex-col items-center justify-end gap-1 text-slate-500 dark:text-slate-400" href="#">
<div class="flex h-8 items-center justify-center">
<span class="material-symbols-outlined">checklist</span>
</div>
<p class="text-xs font-bold leading-normal tracking-[0.015em]">Tasks</p>
</a>
<a class="flex flex-1 flex-col items-center justify-end gap-1 text-primary" href="#">
<div class="flex h-8 items-center justify-center">
<span class="material-symbols-outlined fill-1">emoji_events</span>
</div>
<p class="text-xs font-bold leading-normal tracking-[0.015em]">Rewards</p>
</a>
<a class="flex flex-1 flex-col items-center justify-end gap-1 text-slate-500 dark:text-slate-400" href="#">
<div class="flex h-8 items-center justify-center">
<span class="material-symbols-outlined">account_circle</span>
</div>
<p class="text-xs font-bold leading-normal tracking-[0.015em]">Profile</p>
</a>
</div>
</div>
</div>
<style>
        .no-scrollbar::-webkit-scrollbar {
            display: none;
        }
        .no-scrollbar {
            -ms-overflow-style: none;
            scrollbar-width: none;
        }
    </style>
</body></html>

<!-- Child: My Tasks -->
<!DOCTYPE html>

<html lang="en"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<script id="tailwind-config">
        tailwind.config = {
            darkMode: "class",
            theme: {
                extend: {
                    colors: {
                        "primary": "#f48c25",
                        "background-light": "#f8f7f5",
                        "background-dark": "#221910",
                    },
                    fontFamily: {
                        "display": ["Plus Jakarta Sans"]
                    },
                    borderRadius: {"DEFAULT": "0.5rem", "lg": "1rem", "xl": "1.5rem", "full": "9999px"},
                },
            },
        }
    </script>
<style>
        body { font-family: 'Plus Jakarta Sans', sans-serif; }
        .kanban-column { min-width: 320px; }
    </style>
<style>
    body {
      min-height: max(884px, 100dvh);
    }
  </style>
  </head>
<body class="bg-background-light dark:bg-background-dark text-slate-900 dark:text-slate-100 min-h-screen font-display">
<div class="relative flex min-h-screen w-full flex-col overflow-x-hidden">
<header class="flex items-center bg-background-light dark:bg-background-dark p-4 pb-2 justify-between sticky top-0 z-10 border-b border-primary/10">
<div class="text-primary flex size-12 shrink-0 items-center justify-center bg-primary/10 rounded-full">
<span class="material-symbols-outlined text-3xl">face_5</span>
</div>
<h2 class="text-slate-900 dark:text-slate-100 text-2xl font-800 leading-tight tracking-tight flex-1 text-center">My Super Board</h2>
<div class="size-12 flex items-center justify-center">
<span class="material-symbols-outlined text-primary text-3xl">emoji_events</span>
</div>
</header>
<div class="flex flex-col gap-3 p-6 bg-white dark:bg-slate-800 mx-4 mt-4 rounded-xl shadow-sm border border-primary/10">
<div class="flex gap-6 justify-between items-center">
<p class="text-slate-900 dark:text-slate-100 text-lg font-bold">Points Earned Today</p>
<div class="flex items-center gap-2 bg-primary/20 px-3 py-1 rounded-full">
<span class="material-symbols-outlined text-primary text-sm">star</span>
<p class="text-primary text-lg font-extrabold">650 pts</p>
</div>
</div>
<div class="h-6 w-full rounded-full bg-primary/10 overflow-hidden border-2 border-primary/5">
<div class="h-full rounded-full bg-primary" style="width: 65%;"></div>
</div>
<p class="text-primary font-bold text-base flex items-center gap-2">
<span class="material-symbols-outlined">rocket_launch</span>
                Almost there! 350 more for a surprise!
            </p>
</div>
<div class="flex-1 overflow-x-auto">
<div class="flex p-4 gap-6 h-full items-start">
<div class="kanban-column flex flex-col gap-4 flex-shrink-0">
<div class="flex items-center gap-2 px-2">
<span class="material-symbols-outlined text-orange-500">list_alt</span>
<h3 class="text-xl font-bold">To Do</h3>
<span class="bg-slate-200 dark:bg-slate-700 text-xs px-2 py-1 rounded-full">2</span>
</div>
<div class="bg-white dark:bg-slate-800 p-4 rounded-xl shadow-md border-b-4 border-primary/30 group">
<div class="flex justify-between items-start mb-3">
<div class="h-12 w-12 rounded-lg bg-orange-100 flex items-center justify-center">
<span class="material-symbols-outlined text-orange-600 text-3xl">brush</span>
</div>
<span class="material-symbols-outlined text-slate-300 cursor-grab active:cursor-grabbing text-3xl">drag_indicator</span>
</div>
<p class="text-primary text-sm font-bold uppercase tracking-wider">Big Task</p>
<p class="text-slate-900 dark:text-slate-100 text-xl font-extrabold mb-2">Art Project</p>
<p class="text-slate-500 dark:text-slate-400 text-base mb-4">Finish the drawing for Grandma</p>
<div class="flex gap-2">
<button class="flex-1 bg-primary text-white font-bold py-3 rounded-lg flex items-center justify-center gap-2">
<span>Start</span>
<span class="material-symbols-outlined text-lg">arrow_forward</span>
</button>
</div>
</div>
<div class="bg-white dark:bg-slate-800 p-4 rounded-xl shadow-md border-b-4 border-primary/30">
<div class="flex justify-between items-start mb-3">
<div class="h-12 w-12 rounded-lg bg-blue-100 flex items-center justify-center">
<span class="material-symbols-outlined text-blue-600 text-3xl">menu_book</span>
</div>
<span class="material-symbols-outlined text-slate-300 cursor-grab text-3xl">drag_indicator</span>
</div>
<p class="text-slate-900 dark:text-slate-100 text-xl font-extrabold mb-2">Reading Time</p>
<p class="text-slate-500 dark:text-slate-400 text-base mb-4">Read 2 chapters of Dino-Stories</p>
</div>
</div>
<div class="kanban-column flex flex-col gap-4 flex-shrink-0">
<div class="flex items-center gap-2 px-2">
<span class="material-symbols-outlined text-primary">play_circle</span>
<h3 class="text-xl font-bold">Doing</h3>
<span class="bg-primary/20 text-primary text-xs px-2 py-1 rounded-full">1</span>
</div>
<div class="bg-white dark:bg-slate-800 p-4 rounded-xl shadow-lg border-2 border-primary ring-4 ring-primary/10">
<div class="w-full h-40 bg-slate-100 rounded-lg mb-4 overflow-hidden relative">
<img class="w-full h-full object-cover" data-alt="A tidy child's bedroom with colorful toys" src="https://lh3.googleusercontent.com/aida-public/AB6AXuC18l4v1LgzqGnfSF-qQF-cxKmrPihKK5JRCHIYhiiICwtEy2zRnaLwvjYfwswDXEhp8FJrejsxdEXuaWB6Yp92Hs5dH2ZwGmPt7cd0_2DlOPdFElJBquAhBRHiP4k2MxvFZZIv1usKUcI2nF-0fFc8IKEBCVoTqxSyvVCM-ytE0qfiD_Hw6p6J_tfkT3wuRTvrfJ93Y3kEFxIUf4bFPXG5TIpMfNPymzWs8Mr5YG5PzvWB8lqdYjk8AqoDKgoHEgjn4Mm_NwFP5IrL"/>
<div class="absolute inset-0 bg-primary/10 flex items-center justify-center">
<span class="material-symbols-outlined text-white text-6xl drop-shadow-md">cleaning_services</span>
</div>
</div>
<div class="flex justify-between items-start mb-1">
<p class="text-primary text-sm font-bold uppercase">Daily Mission</p>
<span class="material-symbols-outlined text-primary cursor-grab text-3xl">drag_indicator</span>
</div>
<p class="text-slate-900 dark:text-slate-100 text-2xl font-extrabold mb-2">Clean Room</p>
<p class="text-slate-500 dark:text-slate-400 text-lg mb-4">Put all the dinosaur toys in the big blue box</p>
<button class="w-full bg-green-500 text-white font-bold py-4 rounded-xl flex items-center justify-center gap-2 shadow-lg active:scale-95 transition-transform">
<span class="material-symbols-outlined text-3xl">check_circle</span>
<span class="text-xl">I'm Done!</span>
</button>
</div>
</div>
<div class="kanban-column flex flex-col gap-4 flex-shrink-0">
<div class="flex items-center gap-2 px-2">
<span class="material-symbols-outlined text-green-500">task_alt</span>
<h3 class="text-xl font-bold">Finished!</h3>
</div>
<div class="bg-green-50 dark:bg-green-900/20 p-4 rounded-xl border-2 border-dashed border-green-200 flex flex-col items-center justify-center py-10 opacity-60">
<span class="material-symbols-outlined text-green-500 text-5xl mb-2">celebration</span>
<p class="text-green-700 dark:text-green-300 font-bold">Drag tasks here</p>
<p class="text-green-600/60 text-sm">to get your rewards!</p>
</div>
</div>
</div>
</div>
<nav class="sticky bottom-0 w-full flex gap-2 border-t border-primary/10 bg-white dark:bg-slate-900 px-4 pb-6 pt-3 shadow-2xl">
<a class="flex flex-1 flex-col items-center justify-end gap-1 rounded-full text-primary" href="#">
<div class="flex h-10 items-center justify-center bg-primary/20 w-16 rounded-full">
<span class="material-symbols-outlined text-3xl">dashboard</span>
</div>
<p class="text-xs font-bold leading-normal tracking-wide">Board</p>
</a>
<a class="flex flex-1 flex-col items-center justify-end gap-1 text-slate-400 dark:text-slate-500" href="#">
<div class="flex h-10 items-center justify-center">
<span class="material-symbols-outlined text-3xl">stars</span>
</div>
<p class="text-xs font-medium leading-normal tracking-wide">Prizes</p>
</a>
<a class="flex flex-1 flex-col items-center justify-end gap-1 text-slate-400 dark:text-slate-500" href="#">
<div class="flex h-10 items-center justify-center">
<span class="material-symbols-outlined text-3xl">account_circle</span>
</div>
<p class="text-xs font-medium leading-normal tracking-wide">Me</p>
</a>
</nav>
</div>
</body></html>

<!-- Parent: Task Kanban -->
<!DOCTYPE html>

<html lang="en"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<title>Parent Dashboard - Task Board</title>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<script id="tailwind-config">
        tailwind.config = {
            darkMode: "class",
            theme: {
                extend: {
                    colors: {
                        "primary": "#f48c25",
                        "background-light": "#f8f7f5",
                        "background-dark": "#221910",
                    },
                    fontFamily: {
                        "display": ["Plus Jakarta Sans"]
                    },
                    borderRadius: {
                        "DEFAULT": "0.5rem",
                        "lg": "1rem",
                        "xl": "1.5rem",
                        "full": "9999px"
                    },
                },
            },
        }
    </script>
<style>
    body {
      min-height: max(884px, 100dvh);
    }
  </style>
  </head>
<body class="bg-background-light dark:bg-background-dark font-display text-slate-900 dark:text-slate-100 min-h-screen">
<!-- Top Navigation / Header -->
<header class="sticky top-0 z-20 bg-background-light/80 dark:bg-background-dark/80 backdrop-blur-md border-b border-primary/10">
<div class="max-w-7xl mx-auto px-4 h-16 flex items-center justify-between">
<div class="flex items-center gap-3">
<div class="bg-primary rounded-lg p-2 flex items-center justify-center text-white">
<span class="material-symbols-outlined">family_history</span>
</div>
<h1 class="text-xl font-bold tracking-tight">Parent Dashboard</h1>
</div>
<div class="flex items-center gap-4">
<button class="p-2 rounded-full hover:bg-primary/10 transition-colors">
<span class="material-symbols-outlined text-primary">notifications</span>
</button>
<div class="size-10 rounded-full bg-primary/20 border-2 border-primary overflow-hidden">
<img class="w-full h-full object-cover" data-alt="Profile picture of the parent user" src="https://lh3.googleusercontent.com/aida-public/AB6AXuACgsXiXnd9qoy8m4b07Mx2OWVeyqiq53-Nd5jyoT0rvFB1NuB8J65zvBpGwUCWhmXv577uRcrdnbbdvB1oiw9ujxdanhgwRZaBljSW9i6Ko32a9JwYifOtvZi0WAW1dheVRoP-zuYdhoTmfya2wBZvrlofAovSmk-ZtFrbp2YWGT_DidzHv5PPU9gxraZUDqtzjs1VBFo9-0x9Ytar-BnZzKVAtlgykF7uR5ZVt94NSN9IkVk33z_Lv9Fxe6JO6BgtqrRg0v5heHR1"/>
</div>
</div>
</div>
</header>
<main class="max-w-7xl mx-auto p-4 md:p-6 pb-32">
<!-- Dashboard Subheader -->
<div class="mb-8 flex flex-col md:flex-row md:items-center justify-between gap-4">
<div>
<h2 class="text-2xl font-bold">Leo's Weekly Tasks</h2>
<p class="text-slate-500 dark:text-slate-400">Manage and track chores for this week</p>
</div>
<div class="flex items-center gap-2 overflow-x-auto pb-2 md:pb-0">
<span class="px-4 py-2 rounded-full bg-primary text-white text-sm font-semibold">Weekly View</span>
<span class="px-4 py-2 rounded-full bg-primary/10 text-primary text-sm font-semibold">Rewards: 450 pts</span>
</div>
</div>
<!-- Kanban Board Container -->
<div class="grid grid-cols-1 md:grid-cols-3 gap-6 items-start">
<!-- To Do Column -->
<div class="flex flex-col gap-4">
<div class="flex items-center justify-between px-2">
<div class="flex items-center gap-2">
<span class="size-3 rounded-full bg-slate-400"></span>
<h3 class="font-bold text-lg">To Do</h3>
<span class="text-xs font-medium bg-slate-200 dark:bg-slate-800 px-2 py-0.5 rounded-full">3</span>
</div>
<button class="text-primary hover:bg-primary/5 p-1 rounded">
<span class="material-symbols-outlined">more_horiz</span>
</button>
</div>
<div class="flex flex-col gap-3">
<!-- Task Card 1 -->
<div class="bg-white dark:bg-slate-800 p-4 rounded-xl shadow-sm border border-slate-200 dark:border-slate-700 hover:shadow-md transition-shadow cursor-grab">
<div class="flex items-start justify-between mb-3">
<div class="bg-blue-100 dark:bg-blue-900/30 p-2 rounded-lg text-blue-600 dark:text-blue-400">
<span class="material-symbols-outlined">cleaning_services</span>
</div>
<span class="text-xs font-bold text-primary bg-primary/10 px-2 py-1 rounded-md">+50 pts</span>
</div>
<h4 class="font-bold text-slate-900 dark:text-white mb-1">Clean Room</h4>
<p class="text-sm text-slate-500 dark:text-slate-400">Tidy up toys and make the bed</p>
<div class="mt-4 flex items-center justify-between">
<div class="flex -space-x-2">
<img class="size-6 rounded-full border-2 border-white dark:border-slate-800" data-alt="Avatar of child Leo" src="https://lh3.googleusercontent.com/aida-public/AB6AXuDyfLSpPO7dH8J4dmPVIFJ4MSjVmEBV2en1iXk4-k2hmt66WzPzCDW016RCyEQ9jukG6vJjz6Fm3VuN4bW_6PLqO8MYnUF3UrZxPdWLDg_gRhi0Ra1UXVMSW2t0mCgq4OjkXTRHGV69_kGLy08buw8qK3KPp3eyCVpJScwm4w5i_vA1V0sGXXhLA6mAYYvwsGr2243xgu1xvGBjESjiykmUZIN2y5JBkTGc1l_2XHtdIc_1yzvuNiHG2QzsaUfZhrUPGaYiB8yWCa0q"/>
</div>
<span class="text-[10px] font-bold uppercase tracking-wider text-slate-400">Chore</span>
</div>
</div>
<!-- Task Card 2 -->
<div class="bg-white dark:bg-slate-800 p-4 rounded-xl shadow-sm border border-slate-200 dark:border-slate-700 hover:shadow-md transition-shadow cursor-grab">
<div class="flex items-start justify-between mb-3">
<div class="bg-green-100 dark:bg-green-900/30 p-2 rounded-lg text-green-600 dark:text-green-400">
<span class="material-symbols-outlined">menu_book</span>
</div>
<span class="text-xs font-bold text-primary bg-primary/10 px-2 py-1 rounded-md">+30 pts</span>
</div>
<h4 class="font-bold text-slate-900 dark:text-white mb-1">Read for 20 mins</h4>
<p class="text-sm text-slate-500 dark:text-slate-400">Any book from the school list</p>
<div class="mt-4 flex items-center justify-between">
<div class="flex -space-x-2">
<img class="size-6 rounded-full border-2 border-white dark:border-slate-800" data-alt="Avatar of child Leo" src="https://lh3.googleusercontent.com/aida-public/AB6AXuCwekJ1gN5LDKArHi6IeDqbP72OWwCXnnr91mEuq1uiWTLSf2kU9FTqmHeagIgFTjJNEn2j3F4G7LIDhwU6AVxBS2Qv82dDl53t0D5PrsqWSFgQs8rVS6rBSXiE92mDhUKGatQRfdd2mT3AElJu2zl9ubwsDiAXfQDJGtQ0EONbtv8sfnBhsisXSe8dnW92bB6Gf4v8-kZSpOJCFFfGMZbYvoYxqjvXToL0w6jU5RVAeIjOUSFaYTNO3msGwHT1bnuo5YOhGXgTekrQ"/>
</div>
<span class="text-[10px] font-bold uppercase tracking-wider text-slate-400">Learning</span>
</div>
</div>
</div>
</div>
<!-- In Progress Column -->
<div class="flex flex-col gap-4">
<div class="flex items-center justify-between px-2">
<div class="flex items-center gap-2">
<span class="size-3 rounded-full bg-primary"></span>
<h3 class="font-bold text-lg">In Progress</h3>
<span class="text-xs font-medium bg-primary/20 text-primary px-2 py-0.5 rounded-full">1</span>
</div>
<button class="text-primary hover:bg-primary/5 p-1 rounded">
<span class="material-symbols-outlined">more_horiz</span>
</button>
</div>
<div class="flex flex-col gap-3">
<div class="bg-white dark:bg-slate-800 p-4 rounded-xl shadow-sm border-l-4 border-l-primary border border-slate-200 dark:border-slate-700 hover:shadow-md transition-shadow cursor-grab">
<div class="flex items-start justify-between mb-3">
<div class="bg-purple-100 dark:bg-purple-900/30 p-2 rounded-lg text-purple-600 dark:text-purple-400">
<span class="material-symbols-outlined">set_meal</span>
</div>
<span class="text-xs font-bold text-primary bg-primary/10 px-2 py-1 rounded-md">+20 pts</span>
</div>
<h4 class="font-bold text-slate-900 dark:text-white mb-1">Feed the Goldfish</h4>
<p class="text-sm text-slate-500 dark:text-slate-400">Morning and evening feeding</p>
<div class="mt-4 flex items-center justify-between">
<div class="flex -space-x-2">
<img class="size-6 rounded-full border-2 border-white dark:border-slate-800" data-alt="Avatar of child Leo" src="https://lh3.googleusercontent.com/aida-public/AB6AXuDF-l0WdDZ-B6SBoDjUKwK8QD92iZ2xcY7CcuwYerNXxvyKmfAPQu452BdjXPCq0Q7Qu8GWhHJQQCbQBcOOgn6mctD5wqhNCGPy5GWN-p1MeBpCe6XX1ExAodEysn8RcvDR8nirDic3VDeeofX3eXNW1TTn_jWXGCuRibrV6SC5-tWETEoe7YqB4RgidUZga8TouSAI3tF-_RztRRCCGfYTkNwVxmSRqWgb7ECMwr1BYCff9ipEbvReJKzwjdvPgF5X10-28BP4V1Va"/>
</div>
<div class="flex items-center gap-1 text-primary text-[10px] font-bold uppercase tracking-wider">
<span class="material-symbols-outlined text-sm">schedule</span>
<span>Active</span>
</div>
</div>
</div>
</div>
</div>
<!-- Done Column -->
<div class="flex flex-col gap-4">
<div class="flex items-center justify-between px-2">
<div class="flex items-center gap-2">
<span class="size-3 rounded-full bg-green-500"></span>
<h3 class="font-bold text-lg">Done</h3>
<span class="text-xs font-medium bg-green-100 dark:bg-green-900/30 text-green-600 px-2 py-0.5 rounded-full">1</span>
</div>
<button class="text-primary hover:bg-primary/5 p-1 rounded">
<span class="material-symbols-outlined">more_horiz</span>
</button>
</div>
<div class="flex flex-col gap-3">
<div class="bg-white dark:bg-slate-800 p-4 rounded-xl shadow-sm border border-slate-200 dark:border-slate-700 opacity-75 hover:opacity-100 transition-opacity">
<div class="flex items-start justify-between mb-3">
<div class="bg-gray-100 dark:bg-gray-700 p-2 rounded-lg text-gray-400">
<span class="material-symbols-outlined">edit_note</span>
</div>
<span class="text-xs font-bold text-green-600 bg-green-100 dark:bg-green-900/40 px-2 py-1 rounded-md">Awarded</span>
</div>
<h4 class="font-bold text-slate-900 dark:text-white mb-1 line-through decoration-slate-400">Homework</h4>
<p class="text-sm text-slate-500 dark:text-slate-400">Complete math worksheet</p>
<div class="mt-4 flex items-center justify-between">
<div class="flex -space-x-2">
<img class="size-6 rounded-full border-2 border-white dark:border-slate-800" data-alt="Avatar of child Leo" src="https://lh3.googleusercontent.com/aida-public/AB6AXuA4vuOyklziWspyu6nd0WMLhDsDlpjJecyxaINiv4FR7azzH9ibTOFhmJFo8ub66JCOEEpngwwjW5Lke1uzrF52-0DpSNkx8-FocwOFl390iDxAYwPPaazZbQj_DB0Ns7kYoH_AQkpssCRfL0171r8sUTEy-8qoBUWJ-ZtUonZGxMwbxhqyinqVxq4N3yVso5Jo9XhQ96z4B-NrwkOCsHJArt0Ae8RRiktjjmpqhrx28AGo8k5y_OaezjiG0nYesBtJZ202hoQRQtMh"/>
</div>
<div class="flex items-center gap-1 text-green-500 text-[10px] font-bold uppercase tracking-wider">
<span class="material-symbols-outlined text-sm">check_circle</span>
<span>Verified</span>
</div>
</div>
</div>
</div>
</div>
</div>
</main>
<!-- Floating Action Button -->
<button class="fixed bottom-24 right-6 size-14 bg-primary text-white rounded-full shadow-lg shadow-primary/40 flex items-center justify-center hover:scale-110 active:scale-95 transition-transform z-30">
<span class="material-symbols-outlined text-3xl">add</span>
</button>
<!-- Bottom Navigation Bar -->
<nav class="fixed bottom-0 left-0 right-0 bg-white/90 dark:bg-background-dark/90 backdrop-blur-lg border-t border-primary/10 px-4 pb-6 pt-3 z-40">
<div class="max-w-md mx-auto flex items-center justify-around">
<a class="flex flex-col items-center gap-1 text-primary" href="#">
<span class="material-symbols-outlined fill-[1]">dashboard</span>
<span class="text-xs font-bold">Tasks</span>
</a>
<a class="flex flex-col items-center gap-1 text-slate-400 dark:text-slate-500 hover:text-primary transition-colors" href="#">
<span class="material-symbols-outlined">emoji_events</span>
<span class="text-xs font-medium">Rewards</span>
</a>
<a class="flex flex-col items-center gap-1 text-slate-400 dark:text-slate-500 hover:text-primary transition-colors" href="#">
<span class="material-symbols-outlined">bar_chart</span>
<span class="text-xs font-medium">Stats</span>
</a>
<a class="flex flex-col items-center gap-1 text-slate-400 dark:text-slate-500 hover:text-primary transition-colors" href="#">
<span class="material-symbols-outlined">settings</span>
<span class="text-xs font-medium">Settings</span>
</a>
</div>
</nav>
</body></html>
