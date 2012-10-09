LibOrange
=========

LibOrange is my third attempt to make a stable Objective-C OSCAR library.  My previous projects with the same objective failed because of two reasons.  The first being that they did not run on a background thread, making the main thread freeze for as long as two seconds at a time.

The other reason that my previous OSCAR projects failed is that they were made with a minimal understanding of the OSCAR protocol.  This is to say that while programming them, I was also reading the OSCAR documentation, figuring things out as I went along.  After making two attempts at a good OSCAR library, you start to think more about the protocol, and your mind is able to better understand how to create software that implements that protocol.  This is why LibOrange is much more successful than TalkToOscar, its predecessor.

Improvements From TalkToOscar
=============================

LibOrange performs network related tasks on a background thread, only using the main thread when needed.  This makes LibOrange a possibility for a GUI application, since it does the threading part for you.

LibOrange is made using a system in which packets are routed between instances of different handlers.  This means that the user of the library only has to implement protocols for different information that it wishes to receive.  For example, if you are not interested in the buddy list, simply don't implement the AIMFeedbagHandlerDelegate.

LibOrange manipulates the Buddy List whenever needed, not creating a new instance every time something changes.  In TalkToOscar, the buddy list was completely re-allocated whenever a modification occurred.  The architecture of LibOrange allows a delegate to receive more detailed information on modifications, such as buddies being deleted, groups being renamed, etc.  Pointers can be kept to buddies, since the buddy list will never be fully reallocated in LibOrange.

LibOrange doesn't sleep for 0.4 seconds every time it sends a SNAC packet.  That's right, TalkToOscar blocked the main thread for 0.4 seconds every time a packet was sent over the network.  LibOrange doesn't do this, because I understood rate limits while making it.  This makes login take around 3 seconds, and pretty much everything else goes much faster.  In TalkToOscar, login took at least 10 seconds, and everything was generally slow and dysfunctional.

When Will it be Finished?
=========================

LibOrange is still a work in progress, and, like all open source software, will never be finished.  For the most part, LibOrange does everything that I originally intended for it to do. I encourage developers to fix any bugs that are discovered, and to add new features.

Where'd You Get the Name "LibOrange"?
=====================================

If you are not familiar, LibPurple is a C library for instant messaging.  I decided to call my OSCAR library LibOrange simply as a joke.  No functions have the word Orange in them, so really LibOrange is just a title, and nothing more.

Open Source Development
=======================

I encourage anybody that wants to fork this project to do so.  It's always good to have multiple people working on something, and to have multiple viewpoints on a project.  Some stuff that you could work on is:

 - Add typing events
 - Make things more stable (e.g fix thread conflicts, add @synchronized, etc.)
 - Better implement rate limiting.

What the hell is wrong with you?
================================

Well, first of all, I have recently adopted an obsession with making IM protocols and rewriting OSCAR APIs. I wrote two more before this, each being more readable than the last. But I'm probably going to end up writing another one after this one, probably in RoR.

License
=======

This project is now under the [Mozilla Public License (MPL)](http://www.mozilla.org/MPL/).
