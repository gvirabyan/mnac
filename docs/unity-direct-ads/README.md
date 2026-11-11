# Unity Ads напрямую в армянском режиме Android — как вернуть

**Что это.** AdMob (Google) запрещает рекламу рядом с армянским текстом,
поэтому без этого изменения в Android-приложении на армянском рекламы нет
совсем. С ним в этом режиме реклама идёт из Unity Ads напрямую, без AdMob.
Русский, английский и весь iOS это не затрагивает: там AdMob, а
Unity/InMobi/Meta подключены через него.

**История.** 31.10.2026 включили (коммит `c2cb44b`), 07.11.2026 откатили
(`a417f9e`), 08.11.2026 вернули снова (`fe38771`, версия 1.2.7+42),
11.11.2026 снова откатили. Сейчас **выключено** — армянский Android без
рекламы. Инструкция ниже — как вернуть.

**Короткие объявления.** В Unity Dashboard → Monetization → Ad Units →
`Interstitial_Android_Direct` → Edit: в **Ad types** снять **Playable**
(реклама-игры), включить **Allow skip after 5 seconds**. Без нового выпуска.

Весь код изменения сохранён здесь в `unity-direct-ads.patch`.

## Как вернуть (5 минут)

1. Из корня проекта:

   ```sh
   git apply --3way docs/unity-direct-ads/unity-direct-ads.patch
   ```

   Если ругается на конфликты — откройте файлы с `<<<<<<<`, оставьте обе
   части по смыслу. Если код с тех пор почти не менялся, проще:
   `git cherry-pick c2cb44b`.

2. **Сверьте версию Unity SDK.** В `android/app/build.gradle.kts` строка
   `implementation("com.unity3d.ads:unity-ads:4.17.0")` должна совпадать с
   версией, которую тянет адаптер `gma_mediation_unity` (pubspec.yaml).
   Узнать её:

   ```sh
   cd android && ./gradlew app:dependencies --configuration releaseRuntimeClasspath | grep unity-ads
   ```

   Если там другая версия — поставьте её в `build.gradle.kts`.

3. **Проверьте ID в Unity Dashboard** (unity.com → проект Mnac → Monetization):
   - Android Game ID: `6170645` (iOS `6170644`, не используется)
   - Placement: `Interstitial_Android_Direct` (Interstitial)

   Они прописаны в `lib/services/unity_direct_ads.dart`. Если placement
   удалили — создайте новый Interstitial и вставьте его имя туда.

4. `flutter analyze`, затем собрать release на Android-телефон, переключить
   приложение на армянский, перезапустить — через ~10 секунд после старта
   должна показаться реклама Unity. Первая загрузка сразу после создания
   placement может дать TIMEOUT — это нормально, попробуйте ещё раз.

5. Поднять версию в `pubspec.yaml` (`x.y.z+N`, N на 1 больше) и выпустить.

## Что делает патч (для понимания)

| Файл | Что |
|---|---|
| `android/app/build.gradle.kts` | добавляет Unity Ads SDK |
| `android/.../UnityAdsChannel.kt` | новый: Kotlin-код, который инициализирует Unity, грузит и показывает рекламу |
| `android/.../MainActivity.kt` | регистрирует этот канал |
| `lib/services/unity_direct_ads.dart` | новый: Dart-сторона канала, Game ID и placement |
| `lib/services/interstitial_ad_service.dart` | выбор сети: Android + армянский → Unity, иначе AdMob (`unityDirect` / `admobAllowed` вместо `adsAllowed`) |
| `lib/app/startup_sequence.dart` | не запускает AdMob, когда работает Unity напрямую |

**Почему свой канал, а не Flutter-плагин** (`unity_ads_plugin`): плагин тянет
iOS-копию Unity SDK через Swift Package Manager, а адаптер AdMob уже тянет
её через CocoaPods — на iOS они конфликтуют.

**Если доход слабый:** вариант — отдельный проект Unity с «no mediation» или
LevelPlay (без AdMob) только для армянского режима.
