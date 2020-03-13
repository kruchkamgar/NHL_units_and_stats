import C from '../constants'
import appReducer from './reducers'
// import { createLogger } from 'redux-logger'
import thunkMiddleware from 'redux-thunk'
import { createStore, applyMiddleware } from 'redux'

import { clearErrors } from '../actions';

 const consoleMessages = store => next => action => {
	let result
	console.groupCollapsed(`dispatching action => ${action.type}`)

	console.log(action.type)
	result = next(action)

	let { errors, allUnits } = store.getState()
	console.log(`

		units: ${allUnits.units.length}
		fetching units: ${allUnits.fetching}
		errors (units): ${errors.length}, ${errors}

	`)
	console.groupEnd()

  if (errors.length !== 0) { 
    store.dispatch(clearErrors()) }

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
