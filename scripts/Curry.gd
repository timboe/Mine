tool
extends Node

#
#  Currying bakes arguments into a function call for later use
#  You can curry some or all of a method's paramters, than
#  provide the remainder at the time of the call.
#
#  Technically implimented via partial application
#
#  Here all but the final parameter is supplied in advance, 
#  but call_me can also accept an array
#
#  One particular use of curry in GDScript is to work around
#  call_deferred's 5-argument limitation.
#

var curry_call=[]
var curry_args=[]

func call_me(arg):
	if curry_call.size()<2:
		pass
	else:
		var ob=curry_call[0]
		var me=curry_call[1]
		var args=[]
		# add the curried arguments
		for arg in curry_args:
			args.append(arg)
		# add the provided argument to the curried ones
		args.append(arg)
		# now do the appropriate Object.call
		ob.callv(me,args)

func curry(ob,me,args):
	curry_call=[ob,me]
	curry_args.clear()
	for arg in args:
		curry_args.append(arg)

func _ready():
	pass
