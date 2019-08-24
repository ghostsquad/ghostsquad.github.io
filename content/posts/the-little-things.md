---
title: "The Little Things"
date: 2019-08-23T18:44:31-07:00
draft: false
---

One thing I've noticed over the years is that the little things in software development often get overlooked as "bike shedding" moments, and yet there's significant value in establishing a standard, convention, and even automation around these overlooked things. Let's dive right in:

### Git Commits

Following [conventional commits](https://www.conventionalcommits.org/en/v1.0.0-beta.4/) standards can allow you to do things like:

1. Automatically generate CHANGELOGs
2. Automatically determine semantic version bump
3. Communicate nature of changes to teammates, public, stakeholders
4. Used to change build pipeline behavior at runtime to publish code automatically
5. Enhance readability of git commit history

I'm in the SRE/DevOps/PaaS space, and I often find myself wishing I had more time to write weekly newsletters  or similar communications to internal teams to increase the visibility of the new features, bugfixes, and other changes that are being delivered. This includes beta releases, and getting volunteers to provide feedback on tools/services before distributing them to the wider engineering organization. With this said, I cannot overstate the value of #1 and #3 in the above list. I don't mean a [hard-to-read, never-ending list](https://about.gitlab.com/releases/) either. Imagine being able to _generate_ a releases page like [Gitlab's 12.2 release](https://about.gitlab.com/2019/08/22/gitlab-12-2-released/index.html). This is theoretically possible through a combination of well-written commits (that are machine parseable) and well-written epics, that can be queried.

Combine this with [Chris Beams': How to Write a Git Commit Message](https://chris.beams.io/posts/git-commit/#seven-rules) and it makes it trivial to go back in time an figure out why something was done.

### Project Structure & Naming

Conventions over Configuration. This applies to a project directory structure & naming too. Here's some benefits of coming up with and sticking to a polyglot convention, similar to [Go project structure recommendations](https://github.com/golang-standards/project-layout).

1. CI/CD templated/generated pipelines
    * If your project name is valid DNS (and all lowercase), it makes it easy to use (without modification) as your kubernetes namespace (or namespace prefix).
    * `Dockerfile` in the root of your repo? We have a pre-baked step to build/publish without any additional configuration.
    * Using `make`? A standard pipeline can make some assumptions for you about commands to run without requiring explicit configuration.
2. Enhance readability & maintenance by teammates and external teams. Sticking to a convention means that someone doesn't need to learn "how _your_ repo does it".
3. New projects can be [templatized/generated](https://github.com/facebook/create-react-app). If you have the pleasure of being able to spinup & deploy greenfield applications on a regular basis, this becomes an automatable step.

### Tags, Labels, Annotations

Again, this is all about automation. It makes sense to have a standard set of keys and a convention for custom keys that are forward compatible with changes to the standard. Use this same standard for your cloud provider, like AWS, as well as Kubernetes resources.

```yaml
company.io/environment: prd
company.io/team: sig-api
company.io/contact: sig-api@company.io
company.io/managed-by: terraform
company.io/fingerprint: abc123
company.io/fingerprint-type: sha1
company.io/component: database
company.io/part-of: wordpress
custom.company.io/something-not-standard: this-is-project-or-team-specific
```

[Dry is an anti-pattern](https://dev.to/jeroendedauw/the-fallacy-of-dry). Some of these are duplicates of [recommended annotations/labels for kubernetes](https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/). Don't worry about duplication. Use them both, because you'll apply the ones above to more things than just K8s resources. Tools that may not be written by your team could potential benefit from the k8s standard.

### And More...

There are probably more little things that are more than bike-shedding momemnts. I'll come up with a followup post.
