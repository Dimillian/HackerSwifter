HackerSwifter
=============

A Swift Hacker News library for iOS and OSX

## Goal

We want to make a new shiny and powerful library for scrapping [Hacker News](https://news.ycombinator.com). Kinda like [LibHN](https://github.com/bennyguitar/libHN) do in Objective-c. But HackerSwifter will add a lot of other features. 


## Limitation

As you know, Hacker News does not provide any official API, so we rely on scrapping the HTML pages in order to convert them into Swift object. This is the only solution at the moment, so things may broke and may not be future proof. 

But hey, the goal is to have a nice and clean library you can plug in your Swift projects. 

## Features

* Fetch the different feed pages (news, jobs, ask...)
* Upvote post
* Login
* Fetch users page
* Fetch comments
* Post comments
* Vote comments
* HN Logic (500 karma comments vote etc...)
* Provide a clear user facing error message
* **Caching mechanism** for offline use
* Full Swift
* Less code possible
* Offer a very clear and consise API
* Easily manageable
* Inteligent scrapping? 

## Tech

We will use `NSURLSession` and no fancy external library.

Each models (Post, User, etc...) will directly expose class method to load itself or a list of itself, exemple. 

`Post.Load(.News, completionClosure([Post]: posts))`
`User.load("username", completionClosure(User: user))`

So no webservice or manager exposed, everything is done at the model level. 

More to come...




