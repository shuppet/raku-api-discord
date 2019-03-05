# Things we have yet to implement

* Truncate message arrays to save memory?
* Allow user to fetch messages *but don't save them to the Channel object*

# Refactor targets

* Abstract the meaning of the JSON response from websocket into meaningful class(es)
* Potential race condition in messages: all Channel.messages should be via a
  Promise so we can "lock" the array while changes are made.
