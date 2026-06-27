/// Single source of truth for every user-facing string.
///
/// All UI text in the app is in Armenian and must be referenced from here.
/// Identifiers and comments stay in English by project convention.
abstract final class AppStrings {
  AppStrings._();

  // App identity.
  static const String appName = 'Դեպի Տուն';
  static const String appTagline = 'Հաշված օրեր մինչև տուն';

  // Bottom navigation.
  static const String navHome = 'Գլխավոր';
  static const String navStats = 'Վիճակագրություն';
  static const String navCalendar = 'Օրացույց';
  static const String navSettings = 'Կարգավորումներ';

  // Time units (full).
  static const String years = 'Տարի';
  static const String months = 'Ամիս';
  static const String weeks = 'Շաբաթ';
  static const String days = 'Օր';
  static const String hours = 'Ժամ';
  static const String minutes = 'Րոպե';
  static const String seconds = 'Վայրկյան';

  // Onboarding.
  static const String onbWelcomeTitle = 'Բարի գալուստ';
  static const String onbWelcomeSubtitle =
      'Հաշվենք միասին քո ճանապարհը՝ դեպի տուն։';
  static const String onbStartDateTitle = 'Ե՞րբ սկսվեց ծառայությունը';
  static const String onbStartDateSubtitle = 'Ընտրիր մեկնարկի ամսաթիվը';
  static const String onbDurationTitle = 'Որքա՞ն է ծառայության տևողությունը';
  static const String onbDurationSubtitle = 'Ընտրիր ժամկետը';
  static const String onbUnitTitle = 'Զորամասը';
  static const String onbUnitSubtitle = 'Ըստ ցանկության';
  static const String onbUnitHint = 'Օր․՝ Ն զորամաս';
  static const String onbNameHint = 'Անունդ (ըստ ցանկության)';
  static const String onbPhotoTitle = 'Անձնական լուսանկար';
  static const String onbPhotoSubtitle = 'Ըստ ցանկության';
  static const String onbAddPhoto = 'Ավելացնել լուսանկար';
  static const String onbChangePhoto = 'Փոխել լուսանկարը';
  static const String onbReviewTitle = 'Ստուգիր տվյալները';
  static const String onbReviewSubtitle = 'Կարող ես ուղղել ամեն ինչ ավելի ուշ';
  static const String onbStart = 'Սկսել';
  static const String onbNext = 'Առաջ';
  static const String onbBack = 'Հետ';
  static const String onbFinish = 'Ավարտել';

  // Duration presets.
  static const String duration24Months = '24 ամիս';
  static const String duration12Months = '12 ամիս';
  static const String durationCustom = 'Այլ ժամկետ';
  static const String durationCustomDaysSuffix = 'օր';

  // Home.
  static const String homeUntilHome = 'Մինչև տուն';
  static const String homeRemainingTitle = 'ՄՆԱՑ';
  static const String homeElapsedTitle = 'ԱՆՑԱՎ';
  static const String homeCompleted = 'Ավարտված է';
  static const String homeProgress = 'Առաջընթաց';
  static const String homeDischargeDate = 'Զորացրման ամսաթիվ';
  static const String homeServedSoFar = 'Անցել է';
  static const String homeServiceDone = 'Շնորհավո՛ր, ծառայությունն ավարտված է';
  static const String homeServiceNotStarted = 'Ծառայությունը դեռ չի սկսվել';

  // Empty state — no soldier yet.
  static const String homeNoSoldierTitle = 'Դեռ տվյալներ չկան';
  static const String homeNoSoldierSubtitle =
      'Ավելացրու քո ծառայության տվյալները և սկսիր հաշվարկը՝ դեպի տուն';
  static const String homeAddSoldier = 'Ավելացնել';

  // Soldier form (add / edit).
  static const String formAddTitle = 'Ավելացնել տվյալները';
  static const String formStartTitle = 'Մեկնարկի ամսաթիվ';
  static const String formEndTitle = 'Զորացրման ամսաթիվ';
  static const String errEndBeforeStart =
      'Զորացրման ամսաթիվը պետք է լինի մեկնարկից հետո';

  // Soldiers (multi-profile).
  static const String soldiersTitle = 'Զինվորներ';
  static const String soldiersAdd = 'Ավելացնել զինվոր';
  static const String soldierActive = 'Ակտիվ';
  static const String soldierUnnamed = 'Անանուն զինվոր';
  static const String soldierDeleteTitle = 'Ջնջե՞լ զինվորին';
  static const String soldierDeleteBody =
      'Այս զինվորի տվյալները կջնջվեն այս սարքից։ Գործողությունն անշրջելի է։';

  // Statistics.
  static const String statsTitle = 'Վիճակագրություն';
  static const String statsDaysServed = 'Անցած օրեր';
  static const String statsDaysRemaining = 'Մնացած օրեր';
  static const String statsWeeksServed = 'Անցած շաբաթներ';
  static const String statsMonthsServed = 'Անցած ամիսներ';
  static const String statsProgress = 'Ընթացքը';
  static const String statsServedVsRemaining = 'Անցած / Մնացած';
  static const String statsMilestonesPeek = 'Հանգրվաններ';

  // Milestones.
  static const String milestonesTitle = 'Հանգրվաններ';
  static const String milestoneLocked = 'Փակ է';
  static const String milestoneUnlocked = 'Հասանելի է';
  static const String milestoneReached = 'Շնորհավո՛ր նոր հանգրվանը';
  static const String milestoneCelebrate = 'Նշել';
  static const String milestoneClose = 'Փակել';

  // Milestone titles by threshold.
  static String milestoneTitle(int percent) => switch (percent) {
        25 => 'Առաջին քառորդը',
        50 => 'Կեսն անցավ',
        75 => 'Երեք քառորդ',
        90 => 'Գրեթե տանն ես',
        95 => 'Վերջին քայլերը',
        99 => 'Մի շունչ մնաց',
        100 => 'Դեպի տուն',
        _ => '$percent%',
      };

  static String milestoneMessage(int percent) => switch (percent) {
        25 => 'Ճանապարհի առաջին քառորդն ետևում է։ Շարունակիր։',
        50 => 'Կեսը հաղթահարված է։ Տունն ավելի մոտ է, քան երբևէ։',
        75 => 'Մնում է ընդամենը մեկ քառորդ։ Ուժ ու համբերություն։',
        90 => 'Արդեն 90%-ն ետևում է։ Տունը ձեռքիդ տակ է։',
        95 => 'Վերջին հատվածն է։ Քիչ է մնացել։',
        99 => 'Գրեթե ավարտ․ ընդամենը մի շունչ։',
        100 => 'Ծառայությունն ավարտված է։ Բարի վերադարձ տուն։',
        _ => '',
      };

  // Calendar.
  static const String calendarTitle = 'Օրացույց';
  static const String calendarStart = 'Մեկնարկ';
  static const String calendarToday = 'Այսօր';
  static const String calendarDischarge = 'Զորացրում';
  static const String calendarMilestone = 'Հանգրվան';
  static const String calendarLegend = 'Նշանակումներ';

  // Settings.
  static const String settingsTitle = 'Կարգավորումներ';
  static const String settingsPersonalization = 'Անհատականացում';
  static const String settingsNotifications = 'Ծանուցումներ';
  static const String settingsData = 'Տվյալներ';
  static const String settingsBackup = 'Պահուստավորում';
  static const String settingsRestore = 'Վերականգնում';
  static const String settingsReset = 'Զրոյացնել հավելվածը';
  static const String settingsPrivacy = 'Գաղտնիություն';
  static const String settingsAbout = 'Ծրագրի մասին';
  static const String settingsFeedback = 'Հետադարձ կապ';
  static const String settingsEditProfile = 'Խմբագրել տվյալները';

  // Personalization.
  static const String persTheme = 'Թեմա';
  static const String persThemeSystem = 'Համակարգային';
  static const String persThemeLight = 'Բաց';
  static const String persThemeDark = 'Մուգ';
  static const String persAccent = 'Շեշտի գույն';
  static const String persBackground = 'Ֆոնի նկար';
  static const String persBackgroundChoose = 'Ընտրել նկար';
  static const String persBackgroundRemove = 'Հեռացնել նկարը';
  static const String persPhoto = 'Պրոֆիլի լուսանկար';
  static const String persFontSize = 'Տառաչափ';
  static const String persFontSmall = 'Փոքր';
  static const String persFontMedium = 'Միջին';
  static const String persFontLarge = 'Մեծ';
  static const String persAnimationLevel = 'Անիմացիաներ';
  static const String persAnimNone = 'Անջատ';
  static const String persAnimReduced = 'Նվազեցված';
  static const String persAnimFull = 'Լրիվ';

  // Notifications.
  static const String notifEnable = 'Միացնել ծանուցումները';
  static const String notifDailyReminder = 'Օրական հիշեցում';
  static const String notifDailyReminderDesc =
      'Եթե այդ օրը չես մտնում հավելված, նշված ժամին կհիշեցնենք';
  static const String notifReminderTime = 'Հիշեցման ժամը';
  static const String notifMilestones = 'Հանգրվանների ծանուցումներ';
  static const String notifTest = 'Փորձնական ծանուցում';
  static const String notifTestBody = 'Ծանուցումներն աշխատում են ✓';
  static const String notifPermissionDenied =
      'Ծանուցումներն արգելափակված են սարքի կարգավորումներում';

  static String daysLeftBody(int days) => 'Մնաց $days օր մինչև տուն';

  // Share card.
  static const String shareTitle = 'Կիսվել';
  static const String shareButton = 'Կիսվել պատկերով';
  static const String shareDaysSuffix = 'օր մինչև տուն';
  static const String shareDischargeLabel = 'Զորացրում';
  static const String shareCompletedTitle = 'Բարի վերադարձ տուն';
  static const String shareFailed = 'Չհաջողվեց կիսվել';
  static String shareText(int days) =>
      'Մնաց $days օր մինչև տուն 🇦🇲 #ԴեպիՏուն';

  // Data dialogs.
  static const String resetConfirmTitle = 'Զրոյացնե՞լ ամեն ինչ';
  static const String resetConfirmBody =
      'Բոլոր տվյալները կջնջվեն այս սարքից։ Այս գործողությունն անշրջելի է։';
  static const String backupDone = 'Պահուստը պահպանված է';
  static const String restoreDone = 'Տվյալները վերականգնված են';
  static const String restoreFailed = 'Չհաջողվեց վերականգնել';

  // About / privacy.
  static const String aboutBody =
      'Դեպի Տուն — հավելված հայ զինվորների համար։ Քո ճանապարհը՝ դեպի տուն, '
      'գեղեցիկ ու ոգևորող ձևով։';
  static const String privacyBody =
      'Բոլոր տվյալները պահվում են միայն քո սարքում։ Հավելվածը չունի սերվեր, '
      'չի հավաքում և չի ուղարկում որևէ տեղեկություն։';
  static const String aboutVersionLabel = 'Տարբերակ';

  // Common.
  static const String save = 'Պահպանել';
  static const String cancel = 'Չեղարկել';
  static const String confirm = 'Հաստատել';
  static const String delete = 'Ջնջել';
  static const String ok = 'Եղավ';
  static const String loading = 'Բեռնում…';
  static const String errorGeneric = 'Ինչ-որ բան սխալ գնաց';

  // Validation.
  static const String errStartDateRequired = 'Ընտրիր մեկնարկի ամսաթիվը';
  static const String errDurationRequired = 'Ընտրիր ծառայության ժամկետը';
  static const String errStartInFuture =
      'Մեկնարկը չի կարող լինել ապագայում, ստուգիր ամսաթիվը';
}
