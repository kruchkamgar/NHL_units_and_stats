import C from '../constants'
import appReducer from './reducers'
// import { createLogger } from 'redux-logger'
import thunkMiddleware from 'redux-thunk'
import { createStore, applyMiddleware } from 'redux'

 const consoleMessages = store => next => action => {
	let result
	console.groupCollapsed(`dispatching action => ${action.type}`)
	console.log('units', store.getState().allUnits.units.length)
	result = next(action)

	let {errors, allUnits } = store.getState()
	console.log(`

		units: ${allUnits.units.length}
		fetching units: ${allUnits.fetching}
		errors (units): ${errors.length}

	`)
	console.groupEnd()

	return result;
}

export default (initialState={}) => {
	return createStore(
		appReducer,
		initialState,
		applyMiddleware(
			thunkMiddleware,
			consoleMessages)
		)
}
