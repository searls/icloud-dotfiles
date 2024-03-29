JsOsaDAS1.001.00bplist00�Vscript_	�/* Usage:
 *
 *   $ osascript things-defer-work.scpt [COMMAND]
 *
 * Where commands can be found at the bottom of this file
 */
 
function isWorkArea (area) {
	return area.name().indexOf('TD') === 0
}

function gatherAllOpenTodosFromListInAreas (list, areas) {
	return list.toDos().filter(todo => {
		return areas.find(area => {
			const todoArea = todo.area() || todo.project()?.area()
			return area.id() === todoArea?.id()			
		})
	})
}

function stringify (o) {
	if (o.map) {
  	return o.map(thing => `${thing.name}`).join('\n')
	} else {
		return o
	}
}

function tagsOn (todo) { 
	return new Set(todo.tagNames().split(', ').filter(tag => tag))
}

function applyTag (todo, tagName) {
	const tags = tagsOn(todo)
	tags.add(tagName)
	todo.tagNames = Array.from(tags).join(', ')
}

function removeTag (todo, tagName) {
	const tags = tagsOn(todo)
	tags.delete(tagName)
	todo.tagNames = Array.from(tags).join(', ')
}

function daySucc (date) {
  return new Date(date.getTime() + 24*60*60*1000)
}

function isWeekend (date) {
  return date.getDay() === 0 || date.getDay() === 6
}

function nextDay (date, weekdaysOnly) {
  const nextDate = daySucc(date)
  if (!weekdaysOnly || !isWeekend (nextDate)) {
    return nextDate
  } else {
    return nextDay(nextDate)
	}
}

function deferUntilNextDay (things, areasFilter, tagName, weekdaysOnly) {
  const areas = things.areas().filter(areasFilter)
  const todos = gatherAllOpenTodosFromListInAreas(things.lists.byName("Today"), areas)
	const deferDate = nextDay(new Date(), weekdaysOnly)
	todos.forEach(todo => {	
		applyTag(todo, tagName)		
		todo.schedule({for: deferDate})
	})
}

function moveBackIntoToday (things, tagName) {
  const todos = things.tags.byName(tagName).toDos()
	todos.forEach(todo => {	
		todo.schedule({for: new Date()})
		removeTag(todo, tagName)
	})
}

function removeRedundantTags (things, tagName) {
  const todos = things.tags.byName(tagName).toDos()
	todos.forEach(todo => {	
		if (todo.activationDate() < new Date()) {
			removeTag(todo, tagName)
		}
	})
}

const things = Application('Things3')

const ARGS = $.NSProcessInfo.processInfo.arguments
const COMMAND = ARGS.count > 2 ? ARGS.objectAtIndex(2).js : 'defer'

switch (COMMAND.toLowerCase().trim()) {
	case 'defer-work':
		deferUntilNextDay(things, isWorkArea, 'work-deferred', true)
		break
	case 'undefer-work':
		moveBackIntoToday(things, 'work-deferred')
		break
	case 'remove-redundant-tags':
		removeRedundantTags(things, 'work-deferred')
		break
	default:
		throw 'Unknown Things deferral command!'
		break
}


                              
jscr  ��ޭ