# Google's "Unsupported languages" publisher policy as it applies to AdMob apps

Research date: 2026-10-15. Google pages were fetched live on that date. WebFetch returns summaries and short quotes, not full verbatim pages, so the quoted fragments below are exact but some surrounding text may be missing.

## Q1. Exact current wording, meaning of "primarily", and whether Armenian is supported

### Takeaway
Google's rule is a single sentence: "We do not allow content that … is not primarily in one of the supported languages." **Armenian is not on the supported list.** Russian and English are. Google does not define "primarily" in the policy. The closest official gloss is AdSense's rejection help page, which says "the majority of your site's content is in a language that AdSense doesn't currently support".

### Cited Findings
- The current Google Publisher Policies page "Unsupported languages" says: "We do not allow content that: is not primarily in one of the supported languages." — [Publisher Policies: Unsupported languages](https://support.google.com/publisherpolicies/answer/10436912?hl=en)
- The supported list on that page, as fetched on 2026-10-15, contains 49 languages: Arabic, Bengali, Bulgarian, Catalan, Chinese (Simplified), Chinese (Traditional), Croatian, Czech, Danish, Dutch, English, Estonian, Filipino, Finnish, French, German, Greek, Gujarati, Hebrew, Hindi, Hungarian, Indonesian, Italian, Japanese, Kannada, Korean, Latvian, Lithuanian, Malay, Malayalam, Marathi, Norwegian, Polish, Portuguese, Punjabi, Romanian, Russian, Serbian, Slovak, Slovenian, Spanish (European), Spanish (Latin American), Swedish, Tamil, Telugu, Thai, Turkish, Ukrainian, Urdu and Vietnamese. **Armenian is absent.** Georgian and Azerbaijani are also absent. — [Publisher Policies: Unsupported languages](https://support.google.com/publisherpolicies/answer/10436912?hl=en)
- Footnotes on that list say only that the AdSense, Ad Manager or AdMob *interface and Help Center* are not available in certain languages. A language can still be a valid content language without them. — [Publisher Policies: Unsupported languages](https://support.google.com/publisherpolicies/answer/10436912?hl=en)
- The page does not define "primarily" and gives no percentage threshold. — [Publisher Policies: Unsupported languages](https://support.google.com/publisherpolicies/answer/10436912?hl=en)
- The AdMob help page "Languages that Google publisher products support" says the following:
  - "Placing Google ad code on pages with content primarily in an unsupported language is not permitted"
  - It lists "the languages that are currently allowed to be the primary language of a site or app".
  - It also says Google serves ads in the appropriate language "even if your site contains multiple supported languages".
  - Source: [AdMob Help: Languages that Google publisher products support](https://support.google.com/admob/answer/9727?hl=en-GB)
- The AdSense version of that page has the same wording and adds: "You can select your site's primary language during the sign-up process." — [AdSense Help answer 9727](https://support.google.com/adsense/answer/9727?hl=en)
- The AdSense rejection page explains "Unsupported language" as "The majority of your site's content is in a language that AdSense doesn't currently support." Its suggested fix is "Consider translating your site into a supported language and resubmitting your application with your revised site." — [AdSense Help: Your AdSense account wasn't approved](https://support.google.com/adsense/answer/81904?hl=en)
- Since February 16, 2025, the Publisher Policies have been consolidated into one Publisher Policies Help Center that covers AdSense, AdMob and Ad Manager. The unsupported-languages rule kept the wording "is not primarily in one of the supported languages". — [Ad Manager Help: Overview of the Google Publisher Policies update (February 2025)](https://support.google.com/admanager/answer/15738900)
- **History (2020 change):**
  - MonetizeMore reports that in August 2020 Google announced it would stop monetizing *new* sites, pages or apps in unsupported languages from September 15, 2020. The same announcement banned ad code on pages "not containing content". — [MonetizeMore](https://www.monetizemore.com/blog/google-stops-showing-ads-unsupported-language-sites-non-content-pages/)
  - Language Magazine (Oct 2020) dates the start for new sites/apps to November 2020. It says that from April 2021 even previously approved sites and apps in unsupported languages would stop earning. — [Language Magazine](https://www.languagemagazine.com/2020/10/29/google-limits-advertising-to-49-languages/)
  - The two sources disagree on dates. Neither quotes or links the original Google announcement.

### Inferences
- An app whose content is Armenian only is plainly non-compliant. An app with full, real Russian and English versions has supported-language content, so the threshold question becomes what "content" Google judges (see Q2).
- The 2020 "existing properties grandfathered" reading should not be relied on. Current policy text has no grandfather clause, and the April 2021 reports point to retroactive enforcement.

### Gaps
- I found no official numeric threshold for "primarily" and no official definition of it.
- I could not locate Google's original 2020 announcement text, only third-party reports.

## Q2. Is compliance judged per app, per screen/page, or per ad request? Do ads shown to users who chose Armenian still violate the rule?

### Takeaway
Google's wording works at the **page/screen level**: "Placing Google ad code on pages with content primarily in an unsupported language is not permitted". The 2025 policies define "screen" to include app screens. So an app that has supported-language versions but still serves ads on screens the user sees in Armenian is, by the literal text, placing ad code on screens whose content is primarily in an unsupported language. Google publishes no explicit app or locale-specific guidance either confirming or excusing this.

### Cited Findings
- The rule is phrased per page: "Placing Google ad code on pages with content primarily in an unsupported language is not permitted". — [AdMob Help answer 9727](https://support.google.com/admob/answer/9727?hl=en-GB); [AdSense Help answer 9727](https://support.google.com/adsense/answer/9727?hl=en)
- The Publisher Policies glossary defines the relevant terms as follows. Its conflict clause says: "If there is a conflict between the definition in this glossary and the specific policy page, the policy page will control." — [Publisher Policies glossary](https://support.google.com/publisherpolicies/table/10563033)
  - **screen:** "The surface where a user interacts with content including but not limited to web pages and app screens."
  - **content:** "Everything presented to users by the publisher …"
- Several 2025 inventory policies are explicitly per screen ("We do not allow Google-served ads on screens: …" without publisher content, with replicated content, with more ads than content). This shows the framework judges individual screens, not only whole properties. — [Overview of Feb 2025 update](https://support.google.com/admanager/answer/15738900); [Ads on screens without publisher-content](https://support.google.com/publisherpolicies/answer/11112688)
- A third-party reading of the 2020 rules says that on a site mostly in a supported language with one page mostly in an unsupported language, "you may not place ad code on that specific page, but you may still monetize the rest of the site." — [MonetizeMore](https://www.monetizemore.com/blog/google-stops-showing-ads-unsupported-language-sites-non-content-pages/)
- On multilingual sites, Google only says it will serve ads in the appropriate language "even if your site contains multiple supported languages". It says nothing to permit mixing supported and *unsupported* languages. — [AdSense Help answer 9727](https://support.google.com/adsense/answer/9727?hl=en)
- One anecdote: an AdMob developer whose main language was supported still got an "unsupported language" flag. They reported fixing it by unchecking, in Play Console, the countries where an unsupported language is used. This suggests the review looks at what users in particular markets see. It is a single forum report, not official guidance. — [Framework7 forum](https://forum.framework7.io/t/how-to-fix-admob-unsupported-language/11934)

### Inferences
- The strictest reading, and the one most consistent with Google's text, is this:
  - Russian/English versions make the app *eligible*, since the property has supported-language content and can pass review.
  - Ad requests from screens rendered in Armenian are still "ad code on pages with content primarily in an unsupported language".
  - The fully compliant design is to **not request or show ads while the UI or content is in Armenian**, and show ads only in the Russian/English modes.
- A looser reading would judge the app as a whole by its primary or default language, the one picked at sign-up. Google's wording does not support it for apps whose real user base sees Armenian. Under this reading, an app whose audience is mostly Armenian-speaking users in Armenia, who will mostly keep Armenian, would arguably still be "primarily" Armenian in practice.
- Enforcement in practice (automated crawlers versus human review of app screenshots or store listing) is not documented. Detection risk is a separate question from compliance.

### Gaps
- I found no official AdMob statement on apps that are multilingual and switch language by locale.
- I found no official statement on whether AdMob evaluates the store listing, the default locale, or what reviewers see.
- I found no Google statement on per-ad-request language detection.

## Q3. Is content that changes with device locale/language acceptable, or could it count as cloaking or misrepresentation?

### Takeaway
Localizing by language is not cloaking in itself. Google's ads cloaking rule explicitly allows "showing a landing page … in different languages". Cloaking means varying content "to try to hide things that might break" the rules. If the Russian/English versions mainly let the app pass review while ads run on Armenian content, that matches the intent element of cloaking/circumvention. The Publisher Policies have no explicit cloaking clause, though the "Misleading representation" policy bars concealing information about "the content itself".

### Cited Findings
- Google Ads' Circumventing systems policy says:
  - "'Cloaking' refers to showing different content on your website to different people … or to Google to try to hide things that might break Google Ads' rules."
  - "It's okay to show slightly different content to different people … like showing a landing page or ad destination in different languages … but the promoted product or service needs to be the same for everyone."
  - Note: this is the *advertiser* policy, not the publisher policy.
  - Source: [Google Ads policy: Circumventing systems](https://support.google.com/adspolicy/answer/15938075?hl=en)
- The Publisher Policies' "Misleading representation" rule says "We do not allow content that: misrepresents, misstates, or conceals information about the publisher, the content creator, the purpose of the content, or the content itself." The fetched text did not address content that varies by audience or language. — [Publisher Policies: Misleading representation](https://support.google.com/publisherpolicies/answer/11185754?hl=en)
- The Feb 2025 Publisher Policies overview has no standalone cloaking policy for publishers. The only "circumvention" item concerns DRM, under "Enabling dishonest behavior". — [Overview of Feb 2025 update](https://support.google.com/admanager/answer/15738900)
- Google Search spam policies define cloaking as showing search engines different content than users to manipulate rankings and mislead users. This is a different context, not ads monetization. — [Google Search spam policies](https://support.google.com/webmasters/answer/66355?hl=en)

### Inferences
- Showing the same app in Armenian, Russian or English based on the system locale, with a switcher, is ordinary localization. It is the kind of language variation Google's ads cloaking text calls acceptable, provided the content is the same in every language.
- Localization does not cure the unsupported-language problem for the Armenian screens. The risk is not "cloaking" as such. The risk is that ads served on Armenian screens still break the language rule.
- If a reviewer (likely using English or another non-Armenian locale) sees English while most real impressions come from Armenian screens, that could look like evasion of the rule. Gating ads so they never load in Armenian mode removes that risk.

### Gaps
- I found no publisher-side (AdMob/AdSense) Google text on locale-based content or on content shown to reviewers versus users.
- The Ads circumvention text is advertiser policy and is applied here only by analogy.

## Q4. Official guidance on bilingual apps or apps for regions whose language is unsupported

### Takeaway
Google gives one remedy: translate the content into a supported language. It gives no special guidance for bilingual apps or for regions whose language is unsupported. Regions are irrelevant: the rule depends on the language of the content, not on where users are.

### Cited Findings
- The official remedy is "Consider translating your site into a supported language and resubmitting your application with your revised site", or applying with another site that is in a supported language. — [AdSense Help answer 81904](https://support.google.com/adsense/answer/81904?hl=en)
- Multi-language support is acknowledged only for *supported* languages ("even if your site contains multiple supported languages"). — [AdSense Help answer 9727](https://support.google.com/adsense/answer/9727?hl=en)
- No Google page found addresses bilingual apps, locale-based switching, or monetizing users in countries whose language is unsupported. Third-party sources only restate the per-page reading. — [MonetizeMore](https://www.monetizemore.com/blog/google-stops-showing-ads-unsupported-language-sites-non-content-pages/)

### Inferences
- The defensible implementation for the depitun app:
  1. Ship full Russian and English localizations.
  2. Initialize and load AdMob ads **only when the active language is Russian or English**.
  3. Show no ads in Armenian mode.
  4. Ideally, list Russian or English as the app's primary language in the AdMob and store metadata.
- Under this design, the per-screen rule and the cloaking concern are both satisfied.
- The proposed design (locale-based default plus a remembered switcher) alone, with ads in every language, is **not clearly compliant**. Most Armenian users would keep Armenian, so most ad impressions would sit on unsupported-language screens.
- Expected revenue then depends on how many users actually use RU/EN. For an Armenian-audience app this may be small.

### Gaps
- No official confirmation that "ads off in Armenian mode" is enough to avoid a flag.
- No data on how AdMob's automated language detection treats apps with mixed locales.
- Google's policy team or AdMob support would need to be asked directly to resolve this.
