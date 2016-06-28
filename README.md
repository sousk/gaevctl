# GAE version manager

gaevctl helps you to dealing with GAE version management.
It list, delete versions squeezed by time based queries.

Usage:
`gaevctl.rb <command> <sort> <num>`

List versions:
```
gaevctl.rb list older 20
gaevctl.rb list newer 20
```

Delete versions:

```
gaevctl.rb delete older 20
```

Delete versions by time passed since last-deployed

```
gaevctl.rb delete passed 7d
gaevctl.rb delete passed 2w
```

Note:
Deleteing command never deletes working versions whose TRAFFIC_SPLIT more than 0,
	  nor bulit-in version whose name include "builtin".
