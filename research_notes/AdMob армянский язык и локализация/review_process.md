# AdMob app review and policy re-review: the "Unsupported language" case (Android + iOS)

Context: Armenian app («Դեպի Տուն») got AdMob Policy Center issue "Unsupported language" with status "Ad serving limited". Plan under evaluation: add Russian and English UI, pick the language from the phone's system language on first launch, and remember the user's choice. Research date: 2026-10-15. Note: no source found that is specific to 2026. All Google help pages were fetched live on this date.

## 1. How AdMob app review and Policy Center "request review" work (automated or manual, timing, which version is checked)

### Takeaway
App readiness review starts automatically once the app is linked to a store. It usually takes 2–3 days and sometimes longer. Policy Center re-review is requested by hand per app, and you choose one of three reasons. The reason decides whether a pass clears all versions or only the new one. Google does not publish whether a human or an automated system does the language check, or what device it uses.

### Cited Findings
- App readiness review starts once the app is linked to at least one supported store. It checks the app source and AdMob policy compliance, whether the app is published and available, and whether store ID, package name and app name are correct. — [AdMob Help: App readiness/review](https://support.google.com/admob/answer/10564477)
- "Reviews typically take 2-3 days, but in some cases we may require more time to evaluate your app." Ad serving may be limited during review. — [AdMob Help 10564477](https://support.google.com/admob/answer/10564477?hl=en)
- The Android package name "is used for the app readiness review so it's important to ensure it correctly identifies your app". A published app must be linked to a supported store to be eligible for review. — [AdMob Help: Add an app](https://support.google.com/admob/answer/9989980?hl=en)
- Request-review steps: Policy center → **Fix** next to the app → "Issues found" → **Start review process** → pick a reason → tick the confirmation → **Request review**. — [AdMob Help: Request a review](https://support.google.com/admob/answer/9192065?hl=en)
- The three review reasons and what a pass does:
  - "Fixed without uploading a new version": a pass removes enforcement from **all** versions.
  - "Uploaded a new version with the fix": a pass removes enforcement **only from the new version**, and older versions stay enforced.
  - "No issues on this app" (labeled incorrectly): a pass removes enforcement from all versions.
  — [AdMob Help 9192065](https://support.google.com/admob/answer/9192065?hl=en)
- "If you're requesting a review because you've fixed issues, make sure you upload the new version of your app to your respective app store before you request a review." — [AdMob Help 9192065](https://support.google.com/admob/answer/9192065?hl=en)
- You "must request a review for each app with policy enforcement(s)". The review statuses are Under review, Rejected and Successful. A rejection comes by email and shows in "Issues found", after which you can change more and request again. A pass is announced by email. — [AdMob Help 9192065](https://support.google.com/admob/answer/9192065?hl=en)
- The violation leaves the Policy center only once no more ad requests come from versions that have it. Older versions "can't be fully restored". The advice is to fix the latest version and encourage users to update. — [AdMob Help 9192065](https://support.google.com/admob/answer/9192065?hl=en); [AdMob Help 15697162](https://support.google.com/admob/answer/15697162?hl=en)
- Policy violations must be fixed. Publisher restrictions are optional and lead to restricted ad serving. — [AdMob Help 9192065](https://support.google.com/admob/answer/9192065?hl=en); [AdMob Help 10448803](https://Support.Google.com/admob/answer/10448803)
- When a Policy center issue is caused by Google Play, the appeal goes through the Play Console Help Center, and replies to the notice email are not reviewed. — [AdMob Help 6195019 (search snippet)](https://support.google.com/admob/answer/6195019?hl=en)
- A 2019 article said violations could be appealed within a 30-day window. It is old and unconfirmed for today. — [Mobile Marketing Magazine](https://mobilemarketingmagazine.com/google-launches-the-app-policy-center-for-publishers/)

### Inferences
- The fix will ship as a new store version, so the matching reason is "Uploaded a new version with the fix". Even after a pass, the old Armenian-only versions on users' phones probably stay enforced until users update. The Policy center entry clears only when those old versions stop sending ad requests.
- The 2–3 day figure is for readiness review. No official turnaround time for a Policy center re-review was found. Expect days, possibly longer.

### Gaps
- No official statement says whether the language re-review is done by a human or automatically, and none says what the reviewer does (opens the app, reads the store listing, or both).
- No official limit on the number of re-review requests was found.
- No published turnaround time for re-reviews specifically.

## 2. What device, language and region reviewers use, and whether the store listing language matters

### Takeaway
Google publishes nothing about reviewers' device language or region. The policy is about the app's **primary** language. Armenian is not on the supported list, while Russian and English are. Store listing matters at least because the review checks the store link. The App Store has no Armenian listing language at all, while Google Play has hy-AM.

### Cited Findings
- Policy text: "We do not allow content that: is not primarily in one of the supported languages." The list of "languages that are currently allowed to be the primary language of a site or app" includes **English** and **Russian** but **not Armenian**. The full list: Arabic, Bengali, Bulgarian, Catalan, Chinese (Simplified/Traditional), Croatian, Czech, Danish, Dutch, English, Estonian, Filipino, Finnish, French, German, Greek, Gujarati, Hebrew, Hindi, Hungarian, Indonesian, Italian, Japanese, Kannada, Korean, Latvian, Lithuanian, Malay, Malayalam, Marathi, Norwegian, Polish, Portuguese, Punjabi, Romanian, Russian, Serbian, Slovak, Slovenian, Spanish (EU/LatAm), Swedish, Tamil, Telugu, Thai, Turkish, Ukrainian, Urdu, Vietnamese. — [Google Publisher Policies: Unsupported languages](https://support.google.com/publisherpolicies/answer/10436912)
- AdMob's language page: "content primarily in an unsupported language is not permitted". If approved, Google "will serve relevant ads to your pages in the appropriate language, even if your site contains multiple supported languages". It does not say how partly translated or mixed-language apps are judged. — [AdMob Help 9727](https://support.google.com/admob/answer/9727?hl=en)
- This policy took effect on 15 Sept 2020 for **new** sites and apps across AdSense, Ad Manager and AdMob. For sites, a page mostly in an unsupported language can't carry ad code, but the rest of a supported-language site can still be monetized. — [MonetizeMore (secondary)](https://www.monetizemore.com/blog/google-stops-showing-ads-unsupported-language-sites-non-content-pages/)
- Developer report (about 2020, Framework7 forum): an app flagged "unsupported language" even though its main languages were supported. It was resolved after the developer **deselected the countries whose languages were unsupported in Play Console** (leaving 12 countries) and requested review again. This is one anecdote, not official guidance. — [Framework7 forum](https://forum.framework7.io/t/how-to-fix-admob-unsupported-language/11934)
- Google Groups threads from 2020 about "Unsupported language": Google staff only pointed to the supported-language list and the AdMob support community, and gave no detail on how the check works. — [Google Groups thread 1](https://groups.google.com/g/google-admob-ads-sdk/c/meC3juWYkOg); [thread 2](https://groups.google.com/g/google-admob-ads-sdk/c/hAxnE4EXolE)
- App Store Connect metadata (listing) languages number 50 and **do not include Armenian**. Russian is included. The default listing language for the Armenia storefront is **English (U.K.)**, with no other languages. — [App Store Connect Help: App Store localizations](https://developer.apple.com/help/app-store-connect/reference/app-information/app-store-localizations)
- Google Play listing language codes include Armenian (hy-AM). — [ibabbleon Play language codes (secondary, 2021)](https://www.ibabbleon.com/Google-Play-Store-Language-Codes.html)

### Inferences
- The Framework7 case suggests that **store signals, such as listing language and target countries, can feed the language decision**, not only the in-app UI. A safe plan has a Play listing whose default language is English or Russian, with hy-AM as an extra translation, rather than an Armenian default listing. It also makes sure the app shows clearly supported-language content to a reviewer whose phone is set to English.
- A reviewer, human or automated, will most likely run the app on a device set to English (or another supported language). With "system language on first launch" logic, that reviewer would see **English UI**, which is good. Risk remains if any screens still show hard-coded Armenian text, such as data from Firestore, push texts or images with Armenian words. The test is whether the content is "primarily" in a supported language.
- Because Armenian is the fallback for unsupported system languages, a reviewer on a phone set to, say, Portuguese would see Armenian. Falling back to **English** for any non-hy/ru system language is safer.

### Gaps
- No source says which device locale or region AdMob reviewers use, or whether they download from the store listing or use crawled or SDK data.
- No case was found where adding English or Russian to an Armenian (or Georgian or Kazakh) app cleared the violation. The outcome cannot be confirmed from public sources.

## 3. Are the iOS and Android apps reviewed separately in AdMob? Does one platform's violation affect the other or the account?

### Takeaway
Yes, they are separate. Each platform is a separate AdMob "app" with its own App ID, store link and review, and Policy center enforcement is per app. Account-level action exists, though: repeated violations "may lead to an account suspension", with no published threshold.

### Cited Findings
- When adding an app, you "Select the platform of your app (Android or iOS)". Each platform gets its own app entry and store link. — [AdMob Help 9989980](https://support.google.com/admob/answer/9989980?hl=en); developer guides confirm one AdMob app and App ID per platform: [FlutterFlow docs](https://docs.flutterflow.io/settings-and-integrations/integrations/admob), [Thunkable community](https://community.thunkable.com/t/solved-admob-apps-do-i-have-to-create-one-for-ios-and-one-for-android/248989)
- You "must request a review for each app with policy enforcement(s)". — [AdMob Help 9192065](https://support.google.com/admob/answer/9192065?hl=en)
- Most statuses (disabled, restricted, at risk, restricted ad personalization) apply to individual apps. "Limited ad serving" and suspension or termination apply to the AdMob **account**. — [AdMob Help 15697162](https://support.google.com/admob/answer/15697162?hl=en)

### Inferences
- If both the iOS and Android apps are flagged, each needs its own fix release and its own review request. A pass on Android does not clear iOS.
- Note: the issue as reported is "Ad serving limited". In Google's terms, "Limited ad serving" is an account-level cap, while an unsupported-language finding is normally an app-level policy issue. Check in the Policy center whether the status is labeled per app or per account. See section 5.

### Gaps
- Nothing says outright whether a language violation on one platform's app raises the risk score of the account or of the other platform's app.

## 4. iOS: Armenian as a system language and per-app language. Android: Armenian system language

### Takeaway
iOS (current feature-availability page) does **not** offer Armenian as a system language. It is only a keyboard language. So on iOS, "pick by system language" never produces Armenian automatically. Armenian users would see Russian or English unless they choose Armenian inside the app. iOS has had per-app language selection since iOS 13. It lists the app's own localizations, but only for localizations the app declares in its bundle. Android's Armenian system language could not be confirmed from a primary source.

### Cited Findings
- Apple's iOS feature-availability "System Language" list (fetched 2026-10-15): Arabic, Bangla, Bulgarian, Catalan, Chinese Simplified, Chinese Traditional (HK, TW), Croatian, Czech, Danish, Dutch, English (AU, IN, UK, US), Finnish, French (CA, FR), German, Greek, Gujarati, Hebrew, Hindi, Hungarian, Indonesian, Italian, Japanese, Kannada, Kazakh, Korean, Lithuanian, Malay, Malayalam, Marathi, Norwegian, Odia, Polish, Portuguese (BR, PT), Punjabi, Romanian, Russian, Slovak, Slovenian, Spanish (LatAm, ES, US), Swedish, Tamil, Telugu, Thai, Turkish, Ukrainian, Urdu, Vietnamese. **Armenian is not a system language.** Armenian appears only under "QuickType Keyboard: Language Support", not in autocorrection, predictive typing or dictation. — [Apple iOS Feature Availability](https://www.apple.com/ios/feature-availability/)
- A similar case: an Apple forum developer reports that Albanian and Macedonian are not selectable as system languages on iOS 16.7 through 26.6.1, even though they are QuickType keyboard languages. This shows that keyboard support does not mean system-language support. — [Apple Developer Forums](https://developer.apple.com/forums/thread/850074)
- Per-app language (iOS 13+): "users can now set the language of your app independent of the system language". The app's Settings page lists "all the languages my application supports". Apple says apps should "not attempt to set the application language manually in code" and should send users to Settings. Changing it relaunches the app. — [WWDC19 session 403](https://developer.apple.com/videos/play/wwdc2019/403/)
- The per-app Language option appears only if the device has more than one language in its preferred list, and only for apps with more than one localization. — [How-To Geek](https://www.howtogeek.com/441716/how-to-change-the-language-of-an-app-on-your-iphone-or-ipad/); [Apple dev forum thread 123413](https://developer.apple.com/forums/thread/123413)
- Android: the Pixel help page describes Settings → System → Language & region → add language, but does not list languages. Samsung hides some languages under "All languages". Supported display languages depend on Android version, maker and carrier. — [Pixel Help](https://support.google.com/pixelphone/answer/12571227?hl=en); [Samsung support](https://www.samsung.com/us/support/answer/ANS10001356/); [Digital Citizen](https://www.digitalcitizen.life/how-change-device-display-language-android/)
- Chromium's Android build config lists "hy" among locales it treats as Android-only. This is indirect evidence that Android has an Armenian locale. — [Chromium locales.gni](https://chromium.googlesource.com/chromium/src/+/refs/tags/81.0.4044.93/build/config/locales.gni)

### Inferences
- On iOS, a Flutter app that reads the system locale will get e.g. `ru` or `en` for Armenian users. That is good for AdMob (a supported language by default), but Armenian users must switch to Armenian with an in-app picker. An in-app picker with the choice remembered is the practical route. Apple's advice against setting the language in code is guidance, not an App Review rule, and Flutter apps commonly do it.
- If the app declares `hy`, `ru` and `en` in CFBundleLocalizations / Info.plist, iOS will show a per-app Language setting. Armenian may appear there as an app localization even though it is not a system language. This was not directly verified for `hy`.
- On Android, many devices (especially Samsung, common in Armenia) likely offer Armenian as the system language. If so, Armenian users get Armenian automatically and reviewers on English devices get English.

### Gaps
- No primary Google/AOSP source confirming that Armenian (hy-AM) is selectable as the Android system display language on Pixel or AOSP builds. To verify, check on a device.
- No confirmation that an `hy` app localization shows in the iOS per-app Language list.

## 5. Consequences of repeated violations or failed re-reviews

### Takeaway
A failed re-review simply leaves the enforcement in place, and you can fix more and ask again. There is no published strike count, but Google says repeated policy violations may lead to account suspension, and account-level actions arrive only by email.

### Cited Findings
- Enforcement ladder: "Violations of the Program policies may result in ad serving restrictions, disabled ad serving, account suspensions, or account termination." "Repeated policy violations may lead to an account suspension." No threshold is given. — [AdMob Help 15697162](https://support.google.com/admob/answer/15697162?hl=en)
- Definitions: **Restricted ad serving** means limits on which advertisers can bid, so demand is usually very low. **Disabled ad serving** means all ads blocked, and you request review after fixing. **Limited ad serving** is an account-level cap on the number of ads. **Ad serving at risk** is a warning with a "fix by" date, after which "further actions may be taken on your app or account". — [AdMob Help 15697162](https://support.google.com/admob/answer/15697162?hl=en); [AdMob Help 10448803](https://Support.Google.com/admob/answer/10448803)
- Rejected review: you're notified by email and in "Issues found", and you can make more changes and request another review. — [AdMob Help 9192065](https://support.google.com/admob/answer/9192065?hl=en)
- Account-level actions are sent only by email from admob-noreply@google.com. Appeals have "no guarantee" of reinstatement, and "further appeals may not be considered". There is a 30-day payment hold after an account is disabled. — [AdMob account disabled FAQ (search summary)](https://SUPPORT.GOOGLE.COM/admob/faq/3364907); [AdSense equivalent](https://support.google.com/adsense/answer/2660562?hl=en)
- Developer forums report accounts disabled with little explanation and unanswered appeals. These are anecdotes. — [Adalo forum](https://forum.adalo.com/t/google-admob-setup-issues-and-experiences-resulted-in-closed-account/50210)

### Inferences
- Requesting re-review before the fixed version is live, or claiming "No issues on this app" for a still-Armenian-primary app, risks a rejection. A record of rejections plausibly counts toward "repeated violations". Ship first, verify what an English-locale device sees, then request review once.
- The listed status "Ad serving limited" could be the account-level "Limited ad serving" (often tied to new or low-quality-traffic accounts) rather than the app-level language issue. Confirm in the AdMob UI which one applies, because they clear in different ways. Limited ad serving is not lifted by a review request.

### Gaps
- No published number of rejected reviews or violations that triggers account suspension.
- No official turnaround time for a Policy center re-review, and no data on pass rates for language-related re-reviews.
