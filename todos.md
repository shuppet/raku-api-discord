# Things we have yet to implement

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

# Refactor targets

* Abstract the meaning of the JSON response from websocket into meaningful class(es)
