# Developer experiences with the AdMob/AdSense "Unsupported language" violation

Research date: 2026-10-15. About 20 search/fetch calls. **Overall signal: public, detailed case reports are scarce.** Most threads end with no confirmed resolution. Google's community forum (support.google.com/admob/community) and Reddit threads did not appear in search results, so the cases below come from Google Groups, third-party dev forums and blogs. No case specifically about an Armenian-language app was found.

## Policy baseline (context for all questions)

### Takeaway
Google's rule is about the *primary* language of the content. Armenian, Georgian, Azerbaijani, Kazakh, Uzbek, Mongolian, Khmer, Burmese, Amharic, Sinhala, Nepali and Kurdish are all absent from the supported list. The rule took effect for new properties in Sept/Nov 2020 and was reported to extend to existing ones from April 2021.

### Cited Findings
- AdMob help lists 50 supported primary languages (Arabic … Vietnamese, including Russian, Turkish, Ukrainian, English). None of Armenian, Georgian, Azerbaijani, Kazakh, Uzbek, Mongolian, Khmer, Burmese, Amharic, Sinhala, Nepali or Kurdish is listed. Quote: "The languages that are currently allowed to be the primary language of a site or app are:" / "Placing Google ad code on pages with content primarily in an unsupported language is not permitted" — [AdMob Help 9727](https://support.google.com/admob/answer/9727?hl=en)
- Publisher Policies wording: "We do not allow content that: is not primarily in one of the supported languages." The page does not address mixed-language content, translations or how language is detected — [Publisher Policies: Unsupported languages](https://support.google.com/publisherpolicies/answer/10436912?hl=en)
- Timeline: new sites/pages/apps in unsupported languages could not be monetized from Sept 15, 2020 (AdSense, Ad Manager, AdMob). The article said existing properties were apparently allowed to continue "at least for now". It also says a page mostly in an unsupported language can't carry ad code, but "you may still monetize the rest of the site" — [MonetizeMore](https://www.monetizemore.com/blog/google-stops-showing-ads-unsupported-language-sites-non-content-pages/)
- From April 2021, "even websites and apps which were previously approved, but are not in one of the supported languages" lose Google ad revenue (Google announcement of Sept 30, 2020, per this article) — [Adnimation](https://www.adnimation.com/google-ad-manager-policy-regarding-supported-languages/); [Language Magazine, 2020-10-29](https://languagemagazine.com/2020/10/29/google-limits-advertising-to-49-languages/)
- AdSense's official advice for language rejections is to translate the site into a supported language and resubmit — [AdSense Help 81904 (via search snippet)](https://support.google.com/adsense/answer/81904?hl=en)

## Did adding English/Russian (or another supported language) fix it? Did default vs. optional matter?

### Takeaway
No public case was found where a developer documented adding an English or Russian localization to an unsupported-language app and then passing re-review. The only documented "fix" for AdMob was a store-distribution change: removing the countries tied to the unsupported language in Play Console, then requesting re-review. The single Google statement about an English-default plus unsupported-second-language app (Myanmar) did not object, but it answered a different question.

### Cited Findings
- **Case: Framework7/Cordova app, Sept 2020 (resolved).** The app was flagged "Unsupported language" although its main languages were on the supported list. Fix: "Go to play Store console and uncheck the country that unsupported language for your app" (kept only 12 countries), then "Re-submit to AdMob Policy Violation Review again." The poster reported this worked. A 2021 reply asking which 12 countries got no answer. — [Framework7 Forum](https://forum.framework7.io/t/how-to-fix-admob-unsupported-language/11934)
- **Case: English-default + Myanmar (Burmese) app, March 6, 2023.** The developer asked whether an app with English as the default and Myanmar as a second language can use AdMob. The Google forum advisor replied only that "Language localization is automatically handled by the AdMob SDK… it will present ads in English or in the region's native language." No policy objection was raised, but the reply addressed ad localization, not the policy question. No follow-up on whether a review passed. — [Google Groups: AdMob multi languages](https://groups.google.com/g/google-admob-ads-sdk/c/7LOIyW1yp-Q)
- **Case: Azerbaijani + Arabic app, March 2020 (unresolved).** The developer complained that ads were limited and called changing his native Azerbaijani "ridiculous." The Google SDK team pointed to the supported-languages article and the Product Support community. No resolution was posted. — [Google Groups: Unsupported language for Admob SDK](https://groups.google.com/g/google-admob-ads-sdk/c/hAxnE4EXolE)
- **Case: unnamed-language app, April 2020 (unresolved).** The developer could not work out what triggered "Unsupported Language." The Google reply pointed only to the supported list. — [Google Groups: Google Admob "Unsupported Language"](https://groups.google.com/g/google-admob-ads-sdk/c/meC3juWYkOg)
- **Case: Kodular app, May 29, 2024 (unresolved).** The app was flagged for unsupported language plus "replicated content." The developer asked whether adding photos as content would help. No replies. — [Kodular Community](https://community.kodular.io/t/need-a-help-for-admob-ad-limit-bcz-unsupported-language/260980)
- **Web-side workaround reported (AdSense):** some sites in unsupported languages got ads served "through a summary of content in a language that the bots understand, usually English," and the article expected bilingual content as a workaround. It is anecdotal, with no named publishers. — [Language Magazine, 2020](https://languagemagazine.com/2020/10/29/google-limits-advertising-to-49-languages/)
- **Georgian site (Google Ads, advertiser side, undated Quora):** ads were disapproved for unsupported language. The suggested fixes were translating to an approved language or asking Google to add the language. No confirmed outcome. — [Quora](https://www.quora.com/My-Google-ads-were-disapproved-due-to-unsupported-language-Can-you-tell-me-what-is-the-problem-My-website-is-in-the-Georgian-language-Ive-got-keywords-in-the-Georgia-language-as-well)
- **AdSense, Russian forum, July 2017 (pre-2020 rule):** a site was rejected for "Неподдерживаемый язык". The owner suspected PHP code fragments and Lorem ipsum placeholder text. The only reply said to contact support. This shows the classifier can be triggered by non-language junk text. — [searchengines.guru](https://searchengines.guru/ru/forum/969177)
- Once an issue is fixed, AdMob lets you request a review from the Policy Center's disapproved-apps page — [AdMob Help: app readiness](https://support.google.com/admob/answer/10564477?hl=en-GB)

### Inferences
- The Framework7 case suggests the review looks at more than in-app strings and may weigh store distribution (countries) and listing languages. This is a single anecdote.
- Since the policy is about the "primary" language, a supported language that is only an option, with an unsupported default, is weaker than a supported default. No public case proves this either way.
- Junk or non-linguistic text (code, Lorem ipsum, very little text) may be read as "unsupported language". Apps with little text, or mostly Armenian strings, are likely to be classified by whatever text the reviewer sees.

### Gaps
- No documented case of an Armenian (or Georgian/Kazakh/etc.) app adding English/Russian localization and then passing or failing re-review.
- No public data on whether reviewers or crawlers use an English or US device locale, or what the store listing's default language is set to. Device-locale-based defaulting was not discussed in any case found.
- Google's AdMob Community and Reddit threads did not surface in search, so a direct manual search of support.google.com/admob/community is recommended.

## Cases where re-review failed even after adding a supported language

### Takeaway
No such case was found documented publicly.

### Cited Findings
- None. The closest are the unresolved threads above, where developers got only a pointer to the supported list ([Google Groups 2020](https://groups.google.com/g/google-admob-ads-sdk/c/meC3juWYkOg); [Google Groups 2020, Azerbaijani](https://groups.google.com/g/google-admob-ads-sdk/c/hAxnE4EXolE)).

### Inferences
- Because Google's responses are templated (the supported-language link plus "contact Product Support"), failed re-reviews probably go unreported publicly, rather than not happening.

### Gaps
- No evidence either way. This would need direct AdMob Community searching or first-hand testing.

## Is locale-based content switching treated as cloaking or misrepresentation?

### Takeaway
No reports were found of Google treating device-locale-based language switching in an app as cloaking for the unsupported-language policy. Google's cloaking definition targets showing *reviewers* different content from *users*, which is distinct from normal localization.

### Cited Findings
- Google Ads' Circumventing Systems policy (third-party summary): cloaking is "showing different content to Google's review systems than to end users" — [ConductAtlas summary of Google Ads policy](https://conductatlas.com/platform/google-ads/google-ads-advertising-policies-overview/prohibited-practices-circumventing-systems/) (secondary source; the Google Ads advertiser policy, not the publisher policy)
- AdSense moderator (older WebmasterWorld thread, per search snippet): modifying ad code to change ad targeting (e.g. forcing English ads on non-English pages) is prohibited — [WebmasterWorld](https://www.webmasterworld.com/google_adsense/4538234.htm)

### Inferences
- Standard OS-locale localization shows every user content in their own locale, including reviewers. It is not reviewer-targeted, so it does not match the cloaking definition. Detecting the reviewer, or forcing English only for review IPs/locales, would match it.
- The real risk is that the policy is about the *primary* language of the audience's content. If nearly all real users (Armenia) see Armenian, Google could still consider the app's primary language unsupported even if a reviewer saw English. This is inference, not documented enforcement.

### Gaps
- No publisher-policy text or case on locale switching in apps specifically.

## Alternative ad networks for unsupported-language apps

### Takeaway
No language-based eligibility restriction was found in public docs for Yandex Advertising Network (mobile), Meta Audience Network, Unity Ads or AppLovin. Google's explicit primary-language list appears unique among them. No first-hand developer migration reports were found.

### Cited Findings
- Yandex Advertising Network (mobile): requirements pages cover ad placement (e.g. refresh no more than every 30 s, or 15 s via Yandex Mediation), supported stores (App Store, Google Play, Huawei AppGallery) and SDK minimums. No app-language requirement was found — [Yandex Ads: requirements for ads in mobile apps](https://boost.yandex.com/doc/en/ad-monetization/payments/yan-rules/display-ads); [Yandex quick start](https://boost.yandex.com/doc/en/ad-monetization/quick-start)
- Yandex's advertiser-side rules (Yandex Direct) explicitly allow Kazakh and Uzbek (and list Armenian) as ad languages for some countries. This is indirect evidence that the network handles these languages — [Yandex Direct ad rules](https://yandex.com/support/direct/en/moderation/ad-rules)
- Meta Audience Network policy covers compliance, ads.txt, and "Meta reserves the right to reject, approve or remove any Publisher or app for any reason". No language list was seen — [Meta AN Policy](https://developers.facebook.com/docs/audience-network/optimization/best-practices/an-policy)
- AppLovin and Unity Ads: no language requirement found. Their official publisher policy pages were not retrieved — [AdMob bidding partners list (for context)](https://admob.google.co.in/home/bidding/bidding-partners/)

### Inferences
- Running Meta, AppLovin or Unity *through AdMob mediation* likely doesn't bypass the restriction if AdMob itself limits the app. Direct SDK integration of a non-Google network would avoid it. Not verified.
- Yandex is the most natural fit for Armenia/CIS audiences (Russian-speaking advertiser base), but fill and eCPM data for Armenia were not found.

### Gaps
- No developer reports of migrating an Armenian/Georgian/etc. app from AdMob to another network, with outcomes.
- AppLovin MAX and Unity Ads publisher policy texts were not checked directly.
