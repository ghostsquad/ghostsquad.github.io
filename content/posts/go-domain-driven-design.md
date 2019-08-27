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

These are typically (but not exclusively) database records.

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

#### Aggregate / Aggregate Root

> A collection of objects that are bound together by a root entity, otherwise known as an `aggregate root`. The aggregate root guarantees the consistency of changes being made within the aggregate by forbidding external objects from holding references to its members.
Example: When you drive a car, you do not have to worry about moving the wheels forward, making the engine combust with spark and fuel, etc.; you are simply driving the car. In this context, the car is an aggregate of several other objects and serves as the aggregate root to all of the other systems.

These are typically (but not exclusively) an entity or group of entities.

According to some research of mine, it's important to hide everything but the `root` object and it's public API methods (such as `Drive()`). In Go, that means names & attributes starting with a lowercase letter.

Getters and Setters are often also considered a code smell. If you need to retrieve the `mileage` of a `wheel`, what are you doing with that data? Maybe the `Car` should be concerned with it instead of this external party.

```go
package car

type wheel struct {
  id string
  mileage int
}

type Car struct {
  Id string
  wheels []*Wheel
}

func New() *Car {
  return &Car{}
}

func (c *Car) Drive() {
  for _, w := range c.wheels {
    w.mileage++
  }
}
```

In this example, when you `Drive()` you increase the mileage on your car. Mileage is a  value bound by the root entity `Car`, and because it's private (not exported), external objects cannot hold a reference to it.

#### Domain Event

> A domain object that defines an event (something that happens). A domain event is an event that domain experts care about. This is produced by the aggregate, and typically is sent to an in-memory and an external message broker such that aggregates within the same process and aggregates in other microservices can subscribe an react to the event.

```go
type MileageIncreaseEvent struct {
  amount int
}
```

#### Service

> When an operation does not conceptually belong to any object. Following the natural contours of the problem, you can implement these operations in services. See also Service (systems architecture).

`--Wikipedia`

> When a significant proess or transformation  in the  domain is not a natural responsibility  of an `entity` or `value object`, add an operation to the model as a standalone interface declared as a `service`. Define the interface in terms of the language of the model and make sure the operation name is part of [ubiquitous language](https://blog.carbonfive.com/2016/10/04/ubiquitous-language-the-joy-of-naming). Make the `service` *stateless*.

A service in Go usually glues multiple aggegrates together.

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
* [https://medium.com/@shijuvar/building-microservices-with-event-sourcing-cqrs-in-go-using-grpc-nats-streaming-and-cockroachdb-983f650452aa](https://medium.com/@shijuvar/building-microservices-with-event-sourcing-cqrs-in-go-using-grpc-nats-streaming-and-cockroachdb-983f650452aa)
* [https://martinfowler.com/bliki/DDD_Aggregate.html](https://martinfowler.com/bliki/DDD_Aggregate.html)
