# Things we have yet to implement

* Handle events e.g. new message, edited message
  * Add new messages to relevant channel array
  * And delete them too
* Rate Limiting
* Fix RESUME
* Reactions
  * Create example for adding reactions
* Emoji
  * Not quite sure what this requires
* Mentions
  * Emit special event?
* Embeds
* Edited messages
  * Update message in memory
* Supplies everywhere!!
  * Add suppy to Channel and Guild for messages
  * And for events
  * Maybe:
    * Add edit supply to Message
    * Add reaction supply to Message
* Partial objects
  * Objects that know they are only partially fetched and will get the rest of
    themselves when requested
* Invites
* Truncate message arrays to save memory?
* Allow user to fetch messages *but don't save them to the Channel object*

# Refactor targets

* Abstract the meaning of the JSON response from websocket into meaningful class(es)
* Potential race condition in messages: all Channel.messages should be via a
  Promise so we can "lock" the array while changes are made.
