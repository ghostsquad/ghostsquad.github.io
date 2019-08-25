---
title: "Go Domain Driven Design"
date: 2019-08-24T21:54:06-07:00
draft: true
toc: false
images:
tags: 
  - untagged
---

I sometimes find myself fumbling around and being indecisive when it comes to how I want to organize my code to follow best practices, SOLID principles, etc. A friend of mine recently asked for some clarifying advice regarding DDD as it relates to Go, so I thought I'd do some research, a see if I can write a post in my own words to ensure I understand and can teach it.

### Building Blocks

First, let's start of with the base building blocks, their definitions, and some example code for each:

#### Entity

> An object that is not defined by its attributes, but rather by a thread of continuity and its identity. Two people with the same name living at the same address are still two different people. On the other hand, you probably would not care if we exchanged dollar bills, as long as both bills have the same value.

```go
// This is an entity
// When comparing to another Person, you must only compare the Id field
type Person struct {
  Id string // uuid perhaps?
  Name string
}
```

#### Value object

> An object that contains attributes but has no conceptual identity. They should be treated as immutable.
Example: When people exchange business cards, they generally do not distinguish between each unique card; they are only concerned about the information printed on the card. In this context, business cards are value objects.

```go
// This is a value object. It has no identity.
// When comparing to another ContactCard, you must compare each field for equality
type ContactCard struct {
  Name string
  Address string
  Phone string
}
```

#### Aggregate

> A collection of objects that are bound together by a root entity, otherwise known as an aggregate root. The aggregate root guarantees the consistency of changes being made within the aggregate by forbidding external objects from holding references to its members.
Example: When you drive a car, you do not have to worry about moving the wheels forward, making the engine combust with spark and fuel, etc.; you are simply driving the car. In this context, the car is an aggregate of several other objects and serves as the aggregate root to all of the other systems.

```go

```

#### Domain Event

> A domain object that defines an event (something that happens). A domain event is an event that domain experts care about.

```go

```

#### Service

> When an operation does not conceptually belong to any object. Following the natural contours of the problem, you can implement these operations in services. See also Service (systems architecture).

```go

```

#### Repository

> Methods for retrieving domain objects should delegate to a specialized Repository object such that alternative storage implementations may be easily interchanged.

```go

```

#### Factory

> Methods for creating domain objects should delegate to a specialized Factory object such that alternative implementations may be easily interchanged.

```go

```

#### References

* [wikipedia/domain-driven-design](https://en.wikipedia.org/wiki/Domain-driven_design)
* [https://github.com/marcusolsson/goddd](https://github.com/marcusolsson/goddd)
