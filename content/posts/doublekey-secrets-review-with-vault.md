---
title: "DoubleKey - A Secrets Review Tool for Vault"
date: 2019-08-29T19:45:53-07:00
draft: true
toc: false
images:
tags: 
  - untagged
---

Back in 2018, as we were rolling out Kubernetes for the company, we decided to use [Hashicorp Vault](https://vault) not just for secrets, but for all configuration. This definitely seemed weird at first, but it really did make a lot of sense. You could store things like entire connection strings (instead of just username and password) in Vault. All your configuration was in one place, and because of that, it eliminated the risk of "drift" between config values and secret values.

There was one problem though. Someone still had to update values, and sometimes it was updating multiple different values in preparation for a deployment. Our continuous deployment process became slightly less streamlined, as it required not just a "merge to master", but also a "config update", and these things had to be coordinated. We did use feature flags, but this also became a slightly manual process. Ensure a flag was disabled, update/add a config, redeploy, turn the flag on incrementally and monitor for problems.

On top of this, we used "global" config variables. Values that were used regardless of what environment you were in (production, staging, etc). Looking back, this is an anti-pattern. Applications should provide reasonable defaults for as much as possible. If this isn't possible (or you need to do something while the team implements it), I suggest "promoted" values instead. A value can start in staging, and be tied to a specific app version. When the version gets promoted to production, so does the value. Otherwise you run into this...

[global config change meteor](https://meteor.png)

Many of these problems though can be mitigated if you could review secrets changes like you would review code changes. As far as I'm aware, nothing currently exists though that acts like a secure "Pull Request" process for key/values stored in Vault. So I got to thinking... this is a really good opportunity to create something new that fills a need in the community.

Introducing [DoubleKey](https://github.com/ghostsquad/doublekey). The name comes from the process you see in movies, where 2 keys are required to open the vault, or launch the missiles, or whatever. If this sounds familiar, it's because Vault uses this mechanism for the unseal process.

The premise is simple. A value and destination-key value are created in temporary staging location within Vault. A policy is assigned to this staging location that allows read/write for selected individuals who are responsible for updating & maintaining configuration values at the _destination_. The `DoubleKey` service then wraps a process of creating the value, requesting review & approvals, recording those approvals in an auditable way, and finally setting the value at the _destination_ location specified, and deleting the values in staging.
