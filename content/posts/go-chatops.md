---
title: "Go Chatops"
date: 2019-08-25T08:42:15-07:00
draft: true
toc: false
images:
tags: 
  - untagged
---

Earlier this year, a coworker and I were working through the developer experience of interacting with our [platform](posts/building-a-platform.md). Several ideas came to mind that we wanted to implement, including:

* [platform cli](posts/building-a-cli-for-your-platform.md)
* slack bot to to get relevant notifications and perform interactive processes
* unified "entrypoint" into the platform, for development as well as reporting
  
I talk about some  of this in another post, [building a platform](posts/building-a-platform.md), so head on over there if you are curious.

Slack though presented a unique opportunity to allow folks to do things _without_ using the terminal (CLI), without developing tools to communicate with our API, and most importantly, without switching context. Since many of the things such as builds, alerts, merge requests, etc all get pushed to slack, why not allow people to respond right then and there to these things.
