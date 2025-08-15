# XIChat

## Overview

XIChat is an addon for FFXI and Windower 4, which servers as the client side of a service that allows for linkshell chat to be mirrored to any number of destinations. The currently supported destinations are Slack and Discord, but new ones can be added at any time without updating the client addon (it's all handled on the server).

XIChat uses secure HTTP (SSL/HTTPS) via a custom-developed native C++ DLL. As far as I am aware, this is the first networking implementation available to Windower addons that allows for secure communication over the internet.

**Note: Because this addon requires an online service, API keys are required for it to work.**

## How does it work?

API keys are issued based on your player/character/toon name, linkshell name, and server name. They will come in the form of a JSON configuration file which can be dropped into the "licenses" folder under the addon.

Matching messages are sent to a custom web service, which handles message normalization/de-duplication, and multicasting.

- **Normalization** - This breaks the message down into a basic representation, independent of variables such as time zone and linkshell slot. This offers several advantages, including the ability to "de-dupe" messages. It's what allows you to crowdsource messages across any number of players in your linkshells to ensure zero downtime. *Note: De-duplication does not currently handle distinguishing between language filtered and non-language filtered messages. For this reason, I recommend turning off language filters for anyone running the addon with an API key.*
- **Multicasting** - The XIChat service will take any matching message sent with your API key, and re-broadcast it to all configured destinations. This means your Discord or Slack access tokens are **never** sent to anyone in your LS; it's configured one time on your account, and XIChat's own API keys handle the rest.

**API keys should be treated like passwords.** Keep them safe.

## FAQs

- **Someone in my LS leaked their API key/license. What do I do?** Each individual license can be revoked on the server. I am working on a way for you to self-revoke keys, but for now you can just let me know. It's worth noting that the API keys are designed to only work for the player/linkshell it was assigned to.
- **I want to set up another destination. How do I do that?** Let me know. Slack and Discord are already supported, so that's easy. If you want something else (SMS, TikTok, etc), let's have a conversation. This would *not* require addon or license updates, multicast is handled 100% on the server side.
- **How much does it cost?** I'll give out a few free licenses to people in my own linkshells. I may also give out limited term trial licenses if you want to try it out. However, it costs me money to host all of this stuff and the cost only increases with use. I don't know what the fee will be, but there will need to be *something* in order for me to justify the hosting cost. I'm thinking somewhere in the realm of $25/year for five licenses per linkshell.
- **What's the best way to use my licenses?** Optimally, you'd distribute licenses across users who collectively give you 24/7/365 coverage of the LS. This way you don't miss anything.
- **What features are coming?** I'm looking to make personal API keys (non-linkshell) that can be used to DM you in Slack or Discord whenever you receive a tell. Are you interested in getting phone notifications when someone pings you in-game?
