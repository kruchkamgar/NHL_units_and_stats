import C from '../constants'
import appReducer from './reducers'
// import { createLogger } from 'redux-logger'
import thunkMiddleware from 'redux-thunk'
import { createStore, applyMiddleware } from 'redux'

/* const consoleMessages = store => next => action => {
	let result
	console.groupCollapsed(`dispatching action => ${action.type}`)
	console.log('ski days', store.getState().allSkiDays.length)
	result = next(action)

	let { allSkiDays, goal, errors, resortNames, allUnits } = store.getState()
	console.log(`

		units: ${allUnits.units.length}
		fetching units: ${allUnits.fetching}
		errors (units): ${errors.length}
		ski days: ${allSkiDays.length}
		goal: ${goal}
		fetching: ${resortNames.fetching}
		suggestions: ${resortNames.suggestions}
		errors: ${errors.length}
	`)
	console.groupEnd()

	return result
} */

export default (initialState={}) => {
	return createStore(
		appReducer,
		initialState,
		applyMiddleware(
			thunkMiddleware /*,
			consoleMessages */)
		)
}
