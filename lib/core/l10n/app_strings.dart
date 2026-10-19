import 'app_language.dart';

/// Single source of truth for every user-facing string.
///
/// All UI text is referenced from here, in Armenian, Russian and English;
/// [language] picks which one is returned. Identifiers and comments stay in
/// English by project convention.
abstract final class AppStrings {
  AppStrings._();

  /// The language every getter answers in. Set by the settings controller.
  static AppLanguage language = AppLanguage.hy;

  static String _t(String hy, String ru, String en) => switch (language) {
        AppLanguage.hy => hy,
        AppLanguage.ru => ru,
        AppLanguage.en => en,
      };

  /// Joins a label to its value, e.g. "Label՝ value" / "Label: value".
  static String labeled(String label, String value) =>
      '$label${_t('՝', ':', ':')} $value';

  // App identity.
  static String get appName => _t('Մնաց', 'Mnac', 'Mnac');
  static String get appTagline => _t(
        'Հաշված օրեր մինչև տուն',
        'Считаные дни до дома',
        'Counting the days until home',
      );

  // Language picker; each language is named in itself.
  static String get settingsLanguage => _t('Լեզու', 'Язык', 'Language');
  static String languageName(AppLanguage l) => switch (l) {
        AppLanguage.hy => 'Հայերեն',
        AppLanguage.ru => 'Русский',
        AppLanguage.en => 'English',
      };

  // Bottom navigation.
  static String get navHome => _t('Գլխավոր', 'Главная', 'Home');
  static String get navStats =>
      _t('Վիճակագրություն', 'Статистика', 'Statistics');
  static String get navCalendar => _t('Օրացույց', 'Календарь', 'Calendar');
  static String get navSettings => _t('Կարգավորումներ', 'Настройки', 'Settings');

  // Time units (full).
  static String get years => _t('Տարի', 'Годы', 'Years');
  static String get months => _t('Ամիս', 'Месяцы', 'Months');
  static String get weeks => _t('Շաբաթ', 'Недели', 'Weeks');
  static String get days => _t('Օր', 'Дни', 'Days');
  static String get hours => _t('Ժամ', 'Часы', 'Hours');
  static String get minutes => _t('Րոպե', 'Минуты', 'Minutes');
  static String get seconds => _t('Վայրկյան', 'Секунды', 'Seconds');

  // Onboarding.
  static String get onbWelcomeTitle =>
      _t('Բարի գալուստ', 'Добро пожаловать', 'Welcome');
  static String get onbWelcomeSubtitle => _t(
        'Հաշվենք միասին քո ճանապարհը՝ դեպի տուն։',
        'Давай вместе считать твой путь домой.',
        "Let's count your way home together.",
      );
  static String get onbStartDateTitle => _t(
        'Ե՞րբ սկսվեց ծառայությունը',
        'Когда началась служба?',
        'When did the service start?',
      );
  static String get onbStartDateSubtitle => _t(
        'Ընտրիր մեկնարկի ամսաթիվը',
        'Выбери дату начала',
        'Pick the start date',
      );
  static String get onbDurationTitle => _t(
        'Որքա՞ն է ծառայության տևողությունը',
        'Сколько длится служба?',
        'How long is the service?',
      );
  static String get onbDurationSubtitle =>
      _t('Ընտրիր ժամկետը', 'Выбери срок', 'Pick the length');
  static String get onbUnitTitle => _t('Զորամասը', 'Воинская часть', 'Unit');
  static String get onbUnitSubtitle =>
      _t('Ըստ ցանկության', 'По желанию', 'Optional');
  static String get onbUnitHint =>
      _t('Օր․՝ Ն զորամաս', 'Напр.: в/ч N', 'E.g. Unit N');
  static String get onbNameHint => _t(
        'Անունդ (ըստ ցանկության)',
        'Твоё имя (по желанию)',
        'Your name (optional)',
      );
  static String get onbPhotoTitle =>
      _t('Անձնական լուսանկար', 'Личное фото', 'Personal photo');
  static String get onbPhotoSubtitle =>
      _t('Ըստ ցանկության', 'По желанию', 'Optional');
  static String get onbAddPhoto =>
      _t('Ավելացնել լուսանկար', 'Добавить фото', 'Add photo');
  static String get onbChangePhoto =>
      _t('Փոխել լուսանկարը', 'Сменить фото', 'Change photo');
  static String get onbReviewTitle =>
      _t('Ստուգիր տվյալները', 'Проверь данные', 'Check the details');
  static String get onbReviewSubtitle => _t(
        'Կարող ես ուղղել ամեն ինչ ավելի ուշ',
        'Всё можно исправить позже',
        'You can change everything later',
      );
  static String get onbStart => _t('Սկսել', 'Начать', 'Start');
  static String get onbNext => _t('Առաջ', 'Далее', 'Next');
  static String get onbBack => _t('Հետ', 'Назад', 'Back');
  static String get onbFinish => _t('Ավարտել', 'Готово', 'Finish');

  // Duration presets.
  static String get duration24Months =>
      _t('24 ամիս', '24 месяца', '24 months');
  static String get duration12Months =>
      _t('12 ամիս', '12 месяцев', '12 months');
  static String get durationCustom =>
      _t('Այլ ժամկետ', 'Другой срок', 'Other length');
  static String get durationCustomDaysSuffix => _t('օր', 'дн.', 'days');

  // Home.
  static String get homeUntilHome => _t('Մինչև տուն', 'До дома', 'Until home');
  static String get homeRemainingTitle => _t('ՄՆԱՑ', 'ОСТАЛОСЬ', 'LEFT');
  static String get homeElapsedTitle => _t('ԱՆՑԱՎ', 'ПРОШЛО', 'PASSED');
  static String get homeRemainingDaysTitle =>
      _t('ՄՆԱՑ · ՕՐԵՐՈՎ', 'ОСТАЛОСЬ · В ДНЯХ', 'LEFT · IN DAYS');
  static String get homeRemainingWeeksTitle =>
      _t('ՄՆԱՑ · ՇԱԲԱԹՆԵՐՈՎ', 'ОСТАЛОСЬ · В НЕДЕЛЯХ', 'LEFT · IN WEEKS');
  static String get homeRemainingMonthsTitle =>
      _t('ՄՆԱՑ · ԱՄԻՍՆԵՐՈՎ', 'ОСТАЛОСЬ · В МЕСЯЦАХ', 'LEFT · IN MONTHS');
  static String get homeElapsedDaysTitle =>
      _t('ԱՆՑԱՎ · ՕՐԵՐՈՎ', 'ПРОШЛО · В ДНЯХ', 'PASSED · IN DAYS');
  static String get homeElapsedWeeksTitle =>
      _t('ԱՆՑԱՎ · ՇԱԲԱԹՆԵՐՈՎ', 'ПРОШЛО · В НЕДЕЛЯХ', 'PASSED · IN WEEKS');
  static String get homeElapsedMonthsTitle =>
      _t('ԱՆՑԱՎ · ԱՄԻՍՆԵՐՈՎ', 'ПРОШЛО · В МЕСЯЦАХ', 'PASSED · IN MONTHS');
  static String homeDaysPassed(int days) => _t(
        'Անցել է $days օր',
        'Прошло дней: $days',
        '$days days passed',
      );
  static String get homeCompleted => _t('Ավարտված է', 'Завершено', 'Completed');
  static String get homeProgress => _t('Առաջընթաց', 'Прогресс', 'Progress');
  static String get homeDischargeDate =>
      _t('Զորացրման ամսաթիվ', 'Дата дембеля', 'Discharge date');
  static String get homeServedSoFar => _t('Անցել է', 'Пройдено', 'Served');
  static String get homeServiceDone => _t(
        'Շնորհավո՛ր, ծառայությունն ավարտված է',
        'Поздравляем, служба завершена!',
        'Congratulations, the service is over!',
      );
  static String get homeServiceNotStarted => _t(
        'Ծառայությունը դեռ չի սկսվել',
        'Служба ещё не началась',
        "The service hasn't started yet",
      );

  // Empty state — no soldier yet.
  static String get homeNoSoldierTitle =>
      _t('Դեռ տվյալներ չկան', 'Данных пока нет', 'No details yet');
  static String get homeNoSoldierSubtitle => _t(
        'Ավելացրու քո ծառայության տվյալները և սկսիր հաշվարկը՝ դեպի տուն',
        'Добавь данные о службе и начни отсчёт до дома',
        'Add your service details and start the countdown home',
      );
  static String get homeAddSoldier => _t('Ավելացնել', 'Добавить', 'Add');

  // Soldier form (add / edit).
  static String get formAddTitle =>
      _t('Ավելացնել տվյալները', 'Добавить данные', 'Add details');
  static String get formNameTitle => _t('Անուն', 'Имя', 'Name');
  static String get formNameHint =>
      _t('Մուտքագրիր անունը', 'Введи имя', 'Enter a name');
  static String get formStartTitle =>
      _t('Մեկնարկի ամսաթիվ', 'Дата начала', 'Start date');
  static String get formEndTitle =>
      _t('Զորացրման ամսաթիվ', 'Дата дембеля', 'Discharge date');
  static String get errNameRequired =>
      _t('Մուտքագրիր անունը', 'Введи имя', 'Enter a name');
  static String get errEndBeforeStart => _t(
        'Զորացրման ամսաթիվը պետք է լինի մեկնարկից հետո',
        'Дата дембеля должна быть позже даты начала',
        'The discharge date must be after the start date',
      );

  // Soldiers (multi-profile).
  static String get soldiersTitle => _t('Զինվորներ', 'Солдаты', 'Soldiers');
  static String get soldiersAdd =>
      _t('Ավելացնել զինվոր', 'Добавить солдата', 'Add a soldier');
  static String get soldierActive => _t('Ակտիվ', 'Активен', 'Active');
  static String get soldierUnnamed =>
      _t('Անանուն զինվոր', 'Солдат без имени', 'Unnamed soldier');
  static String get soldierDeleteTitle =>
      _t('Ջնջե՞լ զինվորին', 'Удалить солдата?', 'Delete this soldier?');
  static String get soldierDeleteBody => _t(
        'Այս զինվորի տվյալները կջնջվեն այս սարքից։ Գործողությունն անշրջելի է։',
        'Данные этого солдата будут удалены с устройства. Это действие нельзя отменить.',
        "This soldier's details will be deleted from this device. This can't be undone.",
      );

  // Statistics.
  static String get statsTitle =>
      _t('Վիճակագրություն', 'Статистика', 'Statistics');
  static String get statsDaysServed =>
      _t('Անցած օրեր', 'Пройдено дней', 'Days served');
  static String get statsDaysRemaining =>
      _t('Մնացած օրեր', 'Осталось дней', 'Days left');
  static String get statsWeeksServed =>
      _t('Անցած շաբաթներ', 'Пройдено недель', 'Weeks served');
  static String get statsMonthsServed =>
      _t('Անցած ամիսներ', 'Пройдено месяцев', 'Months served');
  static String get statsProgress => _t('Ընթացքը', 'Прогресс', 'Progress');
  static String get statsServedVsRemaining =>
      _t('Անցած / Մնացած', 'Пройдено / Осталось', 'Served / Left');
  static String get statsMilestonesPeek =>
      _t('Նվաճումներ', 'Достижения', 'Achievements');

  // Push history (announcements).
  static String get announcementsTitle =>
      _t('Ծանուցումներ', 'Уведомления', 'Notifications');
  static String get announcementsEmpty => _t(
        'Ծանուցումներ դեռ չկան',
        'Уведомлений пока нет',
        'No notifications yet',
      );
  static String get announcementsEmptySubtitle => _t(
        'Այստեղ կպահվեն բոլոր ծանուցումները, որոնք ուղարկում ենք։',
        'Здесь будут храниться все уведомления, которые мы отправляем.',
        'Every notification we send will be kept here.',
      );
  static String get announcementsError => _t(
        'Չհաջողվեց բեռնել ծանուցումները',
        'Не удалось загрузить уведомления',
        "Couldn't load the notifications",
      );
  static String get announcementsErrorSubtitle => _t(
        'Ստուգեք ինտերնետ կապը և փորձեք կրկին։',
        'Проверьте подключение к интернету и попробуйте снова.',
        'Check your internet connection and try again.',
      );

  // Milestones.
  static String get milestonesTitle =>
      _t('Նվաճումներ', 'Достижения', 'Achievements');
  static String get milestoneLocked => _t('Փակ է', 'Закрыто', 'Locked');
  static String get milestoneUnlocked => _t('Հասանելի է', 'Открыто', 'Unlocked');

  /// Bottom line of a milestone card: when it opens / opened.
  static String milestoneOpensOn(String date) =>
      _t('Կբացվի՝ $date', 'Откроется: $date', 'Opens: $date');
  static String milestoneOpenedOn(String date) =>
      _t('Բացվել է՝ $date', 'Открыто: $date', 'Opened: $date');

  /// How far off a locked milestone is, shown after its date.
  static String milestoneInDays(int days) => switch (days) {
        <= 0 => _t('այսօր', 'сегодня', 'today'),
        1 => _t('վաղը', 'завтра', 'tomorrow'),
        _ => _t('$days օր հետո', 'через $days дн.', 'in $days days'),
      };
  static String get milestoneReached => _t(
        'Շնորհավո՛ր նոր նվաճումը',
        'Поздравляем с новым достижением!',
        'Congratulations on a new achievement!',
      );

  /// Header of the same dialog when it recaps a milestone the user reached
  /// earlier today rather than in this moment.
  static String get milestoneReachedToday => _t(
        'ԱՅՍՕՐՎԱ ՆՎԱՃՈՒՄԸ',
        'ДОСТИЖЕНИЕ ДНЯ',
        "TODAY'S ACHIEVEMENT",
      );
  static String get milestoneShare => _t(
        'Կիսվել նվաճումով',
        'Поделиться достижением',
        'Share the achievement',
      );

  /// Kicker printed above the milestone on the shareable card.
  static String get milestoneShareBadge =>
      _t('ՆՎԱՃՈՒՄ', 'ДОСТИЖЕНИЕ', 'ACHIEVEMENT');

  static String milestoneShareText(String title, int days) => _t(
        '$title 🎖️ Մնաց $days օր մինչև տուն 🇦🇲 #ԴեպիՏուն',
        '$title 🎖️ До дома осталось дней: $days 🇦🇲 #ДепиТун',
        '$title 🎖️ $days days left until home 🇦🇲 #DepiTun',
      );
  static String get milestoneCelebrate => _t('Նշել', 'Отметить', 'Celebrate');
  static String get milestoneClose => _t('Փակել', 'Закрыть', 'Close');

  /// Unit shown under a milestone's number: days served, days left.
  static String get milestoneUnitDays => _t('օր', 'дней', 'days');
  static String get milestoneUnitLeft => _t('մնաց', 'осталось', 'left');

  // Milestone titles, keyed by catalogue id (see MilestoneCatalog).
  static String milestoneTitle(String id) => switch (id) {
        'day30' => _t('Առաջին ամիսը', 'Первый месяц', 'The first month'),
        'day100' =>
          _t('100 օր ծառայություն', '100 дней службы', '100 days of service'),
        'day180' => _t('Կես տարի', 'Полгода', 'Half a year'),
        'day300' => _t('300 օր', '300 дней', '300 days'),
        'day365' => _t('Մեկ տարի', 'Один год', 'One year'),
        'day500' => _t('500 օր', '500 дней', '500 days'),
        'left300' =>
          _t('Մնաց 300 օր', 'Осталось 300 дней', '300 days left'),
        'left200' =>
          _t('Մնաց 200 օր', 'Осталось 200 дней', '200 days left'),
        'left100' =>
          _t('Մնաց 100 օր', 'Осталось 100 дней', '100 days left'),
        'left50' => _t('Մնաց 50 օր', 'Осталось 50 дней', '50 days left'),
        'left7' =>
          _t('Վերջին շաբաթը', 'Последняя неделя', 'The last week'),
        'left1' => _t('Վաղը տուն', 'Завтра домой', 'Home tomorrow'),
        'pct25' =>
          _t('Առաջին քառորդը', 'Первая четверть', 'The first quarter'),
        'pct50' => _t('Կեսն անցավ', 'Половина позади', 'Halfway there'),
        'pct75' => _t('Երեք քառորդ', 'Три четверти', 'Three quarters'),
        'pct90' => _t('Գրեթե տանն ես', 'Почти дома', 'Almost home'),
        'pct99' => _t('Մի շունչ մնաց', 'Остался один вдох', 'One breath left'),
        'pct100' => _t('Դեպի տուն', 'Домой', 'Homeward'),
        _ => '',
      };

  static String milestoneMessage(String id) => switch (id) {
        'day30' => _t(
            'Առաջին ամիսն ամբողջությամբ ետևում է։',
            'Первый месяц полностью позади.',
            'The whole first month is behind you.',
          ),
        'day100' => _t(
            'Հարյուր օր ծառայություն՝ ետևում։',
            'Сто дней службы позади.',
            'A hundred days of service behind you.',
          ),
        'day180' => _t(
            'Վեց ամիս ծառայություն՝ ետևում։',
            'Шесть месяцев службы позади.',
            'Six months of service behind you.',
          ),
        'day300' => _t(
            'Երեք հարյուր օր՝ ետևում։',
            'Триста дней позади.',
            'Three hundred days behind you.',
          ),
        'day365' => _t(
            'Մեկ ամբողջ տարի ծառայություն։',
            'Целый год службы.',
            'A whole year of service.',
          ),
        'day500' => _t(
            'Հինգ հարյուր օր՝ ետևում։',
            'Пятьсот дней позади.',
            'Five hundred days behind you.',
          ),
        'left300' => _t(
            'Մնացած օրերն արդեն երեք հարյուրից քիչ են։',
            'Осталось меньше трёхсот дней.',
            'Fewer than three hundred days to go.',
          ),
        'left200' => _t(
            'Մնացած օրերն արդեն երկու հարյուրից քիչ են։',
            'Осталось меньше двухсот дней.',
            'Fewer than two hundred days to go.',
          ),
        'left100' => _t(
            'Մնացած օրերն արդեն երկնիշ են։',
            'Осталось уже двузначное число дней.',
            'The days left are down to two digits.',
          ),
        'left50' => _t(
            'Մնաց ընդամենը հիսուն օր։',
            'Осталось всего пятьдесят дней.',
            'Only fifty days to go.',
          ),
        'left7' => _t(
            'Վերջին շաբաթն է․ տունը շատ մոտ է։',
            'Последняя неделя — дом совсем близко.',
            'The last week: home is very close.',
          ),
        'left1' => _t(
            'Վաղը տուն ես վերադառնում։',
            'Завтра ты возвращаешься домой.',
            "Tomorrow you're going home.",
          ),
        'pct25' => _t(
            'Ճանապարհի առաջին քառորդն ետևում է։ Շարունակիր։',
            'Первая четверть пути позади. Продолжай.',
            'The first quarter of the way is behind you. Keep going.',
          ),
        'pct50' => _t(
            'Կեսը հաղթահարված է։ Տունն ավելի մոտ է, քան երբևէ։',
            'Половина пройдена. Дом ближе, чем когда-либо.',
            'Half is done. Home is closer than ever.',
          ),
        'pct75' => _t(
            'Մնում է ընդամենը մեկ քառորդ։ Ուժ ու համբերություն։',
            'Осталась всего четверть. Сил и терпения.',
            'Only a quarter left. Strength and patience.',
          ),
        'pct90' => _t(
            'Արդեն 90%-ն ետևում է։ Տունը ձեռքիդ տակ է։',
            'Уже 90% позади. Дом совсем рядом.',
            '90% is already behind you. Home is within reach.',
          ),
        'pct99' => _t(
            'Գրեթե ավարտ․ ընդամենը մի շունչ։',
            'Почти конец — всего один вдох.',
            'Almost done: just one breath away.',
          ),
        'pct100' => _t(
            'Ծառայությունն ավարտված է։ Բարի վերադարձ տուն։',
            'Служба окончена. С возвращением домой!',
            'The service is over. Welcome home!',
          ),
        _ => '',
      };

  // Calendar.
  static String get calendarTitle => _t('Օրացույց', 'Календарь', 'Calendar');
  static String get calendarStart => _t('Մեկնարկ', 'Начало', 'Start');
  static String get calendarToday => _t('Այսօր', 'Сегодня', 'Today');
  static String get calendarDischarge => _t('Զորացրում', 'Дембель', 'Discharge');
  static String get calendarMilestone =>
      _t('Նվաճում', 'Достижение', 'Achievement');
  static String get calendarLegend => _t('Նշանակումներ', 'Обозначения', 'Legend');

  // Settings.
  static String get settingsTitle =>
      _t('Կարգավորումներ', 'Настройки', 'Settings');
  static String get settingsNotifications =>
      _t('Ծանուցումներ', 'Уведомления', 'Notifications');
  static String get settingsData => _t('Տվյալներ', 'Данные', 'Data');
  static String get settingsBackup =>
      _t('Պահուստավորում', 'Резервная копия', 'Backup');
  static String get settingsRestore =>
      _t('Վերականգնում', 'Восстановление', 'Restore');
  static String get settingsReset =>
      _t('Զրոյացնել հավելվածը', 'Сбросить приложение', 'Reset the app');
  static String get settingsPrivacy =>
      _t('Գաղտնիություն', 'Конфиденциальность', 'Privacy');
  static String get settingsAbout =>
      _t('Ծրագրի մասին', 'О приложении', 'About');
  static String get settingsFeedback =>
      _t('Հետադարձ կապ', 'Обратная связь', 'Feedback');
  static String get settingsEditProfile =>
      _t('Խմբագրել տվյալները', 'Изменить данные', 'Edit details');

  // Theme — the only app-level visual preference, shown on the settings page.
  static String get persTheme => _t('Թեմա', 'Тема', 'Theme');
  static String get persThemeSystem => _t('Ավտոմատ', 'Авто', 'Auto');
  static String get persThemeLight => _t('Բաց', 'Светлая', 'Light');
  static String get persThemeDark => _t('Մուգ', 'Тёмная', 'Dark');

  // Used by the soldier form's photo tile (the photo doubles as the home
  // background), not by any settings screen.
  static String get persBackgroundRemove =>
      _t('Հեռացնել նկարը', 'Удалить фото', 'Remove photo');

  // AI cartoon portrait screen, opened from the home top row.
  static String get cartoonTitle =>
      _t('Մուլտ կերպար', 'Мультяшный портрет', 'Cartoon portrait');
  static String get cartoonHint => _t(
        'Ընտրիր լուսանկար, և այն կդառնա մուլտֆիլմի կադր',
        'Выбери фото, и оно станет кадром из мультфильма',
        'Pick a photo and it becomes a cartoon frame',
      );
  static String get cartoonMake =>
      _t('Դարձնել մուլտհերոս', 'Сделать мультяшным', 'Make it a cartoon');
  static String get cartoonPickPhoto =>
      _t('Ընտրել լուսանկար', 'Выбрать фото', 'Pick a photo');
  static String get cartoonOtherPhoto =>
      _t('Ընտրել այլ լուսանկար', 'Выбрать другое фото', 'Pick another photo');
  static String get cartoonRetry => _t('Կրկին', 'Ещё раз', 'Try again');
  static String get cartoonOriginal => _t('Բնօրինակ', 'Оригинал', 'Original');
  static String get cartoonResult => _t('Մուլտ', 'Мульт', 'Cartoon');
  static String get cartoonSetAsPhoto =>
      _t('Դնել որպես լուսանկար', 'Сделать фото профиля', 'Use as photo');
  static String get cartoonApplied =>
      _t('Լուսանկարը թարմացվեց', 'Фото обновлено', 'Photo updated');
  static String get cartoonConsentBody => _t(
        'Մուլտ կերպար ստեղծելու համար լուսանկարը կուղարկվի OpenAI '
            'ծառայությանը։ Այն չի պահվում մեր կողմից։ Շարունակե՞լ։',
        'Чтобы создать мультяшный портрет, фото будет отправлено в сервис '
            'OpenAI. Мы его не храним. Продолжить?',
        'To make the cartoon portrait, the photo is sent to the OpenAI '
            "service. We don't keep it. Continue?",
      );
  static String get cartoonContinue =>
      _t('Շարունակել', 'Продолжить', 'Continue');
  static String get cartoonGenerating => _t(
        'Ստեղծում ենք մուլտ կերպարը… Սա կարող է տևել մինչև մեկ րոպե։',
        'Создаём мультяшный портрет… Это может занять до минуты.',
        'Making the cartoon portrait… This can take up to a minute.',
      );
  static String get cartoonFailedNetwork => _t(
        'Չհաջողվեց ստեղծել նկարը։ Ստուգիր ինտերնետը և փորձիր կրկին։',
        'Не удалось создать картинку. Проверь интернет и попробуй снова.',
        "Couldn't make the picture. Check the internet and try again.",
      );
  static String get cartoonFailedRejected => _t(
        'Այս լուսանկարով հնարավոր չէ ստեղծել նկար։ Փորձիր այլ լուսանկար։',
        'С этим фото картинку создать нельзя. Попробуй другое фото.',
        "This photo can't be turned into a picture. Try another photo.",
      );
  static String get cartoonFailedOther => _t(
        'Չհաջողվեց ստեղծել նկարը։ Փորձիր մի փոքր ուշ։',
        'Не удалось создать картинку. Попробуй чуть позже.',
        "Couldn't make the picture. Try again a little later.",
      );

  // Notifications — one master toggle; the daily reminder and milestone
  // alerts follow it automatically and have no separate UI.
  static String get notifEnable => _t(
        'Միացնել ծանուցումները',
        'Включить уведомления',
        'Turn on notifications',
      );

  // Shown when the OS will no longer raise its own permission dialog: the
  // system prompt is a one-time offer, so the only way back is the settings
  // app, and this asks before sending the user there.
  static String get notifBlockedTitle => _t(
        'Ծանուցումներն անջատված են',
        'Уведомления выключены',
        'Notifications are off',
      );
  static String get notifBlockedBody => _t(
        'Դուք նախկինում մերժել եք ծանուցումները։ Հեռախոսի կարգավորումներում '
            'միացրեք դրանք, որպեսզի ստանաք ամենօրյա հիշեցումներն ու նվաճումների '
            'մասին ծանուցումները։',
        'Ранее вы отклонили уведомления. Включите их в настройках телефона, '
            'чтобы получать ежедневные напоминания и уведомления о достижениях.',
        'You turned notifications down earlier. Turn them on in the phone '
            'settings to get the daily reminders and achievement alerts.',
      );
  static String get notifOpenSettings =>
      _t('Բացել կարգավորումները', 'Открыть настройки', 'Open settings');
  static String get notifSettingsUnavailable => _t(
        'Չհաջողվեց բացել կարգավորումները',
        'Не удалось открыть настройки',
        "Couldn't open the settings",
      );

  // ---- Rate the app ----
  // Raised after a few launches. Asks everyone alike: the stores forbid
  // routing only happy users to the review page.
  static String get rateTitle => _t(
        'Գնահատե՞լ «Մնաց»-ը',
        'Оцените «Mnac»',
        'Rate Mnac',
      );
  static String get rateBody => _t(
        'Ձեր գնահատականը կօգնի ուրիշներին գտնել հավելվածը, իսկ մեզ՝ '
            'դարձնել այն ավելի լավը։ Դա կխլի ընդամենը մի քանի վայրկյան։',
        'Ваша оценка поможет другим найти приложение, а нам — сделать его '
            'лучше. Это займёт всего несколько секунд.',
        'Your rating helps others find the app and helps us make it better. '
            'It only takes a few seconds.',
      );
  static String get rateNow => _t('Գնահատել', 'Оценить', 'Rate');
  static String get rateLater => _t('Ոչ հիմա', 'Не сейчас', 'Not now');

  /// Name and description of the Android channel the local reminders use.
  static String get notifChannelName =>
      _t('Հիշեցումներ', 'Напоминания', 'Reminders');
  static String get notifChannelDescription =>
      _t('Մնաց հիշեցումներ', 'Напоминания Mnac', 'Mnac reminders');

  /// Fixed labels of the home-screen widget, around the day count.
  static String get widgetDaysUnit => _t('օր', 'дн.', 'days');
  static String get widgetUntilHome =>
      _t('մինչև տուն', 'до дома', 'until home');

  static String daysLeftBody(int days) => _t(
        'Մնաց $days օր մինչև տուն',
        'До дома осталось дней: $days',
        '$days days left until home',
      );

  // Share card.
  static String get shareTitle => _t('Կիսվել', 'Поделиться', 'Share');
  static String get shareButton =>
      _t('Կիսվել պատկերով', 'Поделиться картинкой', 'Share as a picture');
  static String get shareToInstagramStory => 'Instagram Stories';
  static String get shareDaysSuffix =>
      _t('օր մինչև տուն', 'дней до дома', 'days until home');
  static String get shareDischargeLabel =>
      _t('Զորացրում', 'Дембель', 'Discharge');
  static String get shareCompletedTitle =>
      _t('Բարի վերադարձ տուն', 'С возвращением домой', 'Welcome home');
  static String get shareFailed =>
      _t('Չհաջողվեց կիսվել', 'Не удалось поделиться', "Couldn't share");
  static String shareText(int days) => _t(
        'Մնաց $days օր մինչև տուն 🇦🇲 #ԴեպիՏուն',
        'До дома осталось дней: $days 🇦🇲 #ДепиТун',
        '$days days left until home 🇦🇲 #DepiTun',
      );

  // Data dialogs.
  static String get resetConfirmTitle =>
      _t('Զրոյացնե՞լ ամեն ինչ', 'Сбросить всё?', 'Reset everything?');
  static String get resetConfirmBody => _t(
        'Բոլոր տվյալները կջնջվեն այս սարքից։ Այս գործողությունն անշրջելի է։',
        'Все данные будут удалены с устройства. Это действие нельзя отменить.',
        "All data will be deleted from this device. This can't be undone.",
      );
  static String get backupDone => _t(
        'Պահուստը պահպանված է',
        'Резервная копия сохранена',
        'Backup saved',
      );
  static String get restoreDone => _t(
        'Տվյալները վերականգնված են',
        'Данные восстановлены',
        'Data restored',
      );
  static String get restoreFailed => _t(
        'Չհաջողվեց վերականգնել',
        'Не удалось восстановить',
        "Couldn't restore",
      );

  // About / privacy.
  static String get aboutBody => _t(
        'Մնաց — հավելված հայ զինվորների համար։ Քո ճանապարհը՝ դեպի տուն, '
            'գեղեցիկ ու ոգևորող ձևով։',
        'Mnac — приложение для армянских солдат. Твой путь домой — красиво '
            'и вдохновляюще.',
        'Mnac is an app for Armenian soldiers. Your way home, in a beautiful '
            'and uplifting way.',
      );
  static String get privacyBody => _t(
        'Բոլոր տվյալները պահվում են միայն քո սարքում։ Հավելվածը չունի սերվեր, '
            'չի հավաքում և չի ուղարկում որևէ տեղեկություն։',
        'Все данные хранятся только на твоём устройстве. У приложения нет '
            'сервера, оно не собирает и не отправляет никакую информацию.',
        'All data is stored only on your device. The app has no server and '
            "doesn't collect or send any information.",
      );
  // While the AI cartoon is switched on, the photo does leave the device —
  // use this wording instead:
  //     'Բոլոր տվյալները պահվում են միայն քո սարքում։ Հավելվածը չունի սերվեր '
  //     'և չի հավաքում քո տվյալները։ Միակ բացառությունը մուլտ կերպարն է․ '
  //     'քո հաստատումից հետո լուսանկարը ուղարկվում է OpenAI ծառայությանը '
  //     'միայն նկարը ստեղծելու համար։'
  static String get aboutVersionLabel => _t('Տարբերակ', 'Версия', 'Version');

  // Common.
  static String get save => _t('Պահպանել', 'Сохранить', 'Save');
  static String get cancel => _t('Չեղարկել', 'Отмена', 'Cancel');
  static String get confirm => _t('Հաստատել', 'Подтвердить', 'Confirm');
  static String get delete => _t('Ջնջել', 'Удалить', 'Delete');
  static String get ok => _t('Եղավ', 'Хорошо', 'OK');
  static String get loading => _t('Բեռնում…', 'Загрузка…', 'Loading…');
  static String get errorGeneric =>
      _t('Ինչ-որ բան սխալ գնաց', 'Что-то пошло не так', 'Something went wrong');

  // Validation.
  static String get errStartDateRequired => _t(
        'Ընտրիր մեկնարկի ամսաթիվը',
        'Выбери дату начала',
        'Pick the start date',
      );
  static String get errDurationRequired => _t(
        'Ընտրիր ծառայության ժամկետը',
        'Выбери срок службы',
        'Pick the length of service',
      );
  static String get errStartInFuture => _t(
        'Մեկնարկը չի կարող լինել ապագայում, ստուգիր ամսաթիվը',
        'Начало не может быть в будущем, проверь дату',
        "The start can't be in the future, check the date",
      );
}
