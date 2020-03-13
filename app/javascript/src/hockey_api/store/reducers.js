import C from '../constants'
import { combineReducers } from 'redux'


export const errors = (state=[], action) => {
  switch(action.type) {
    case C.ADD_ERROR :
    	return [
         ...state,
         action.payload
    	]
    case C.CLEAR_ERROR :
      return state.filter((message, i) => i !== action.payload)
    case C.CLEAR_ERRORS :
      return []
  	default:
  		return state
  }
}

// stored upon dispatch
export const fetching = (state=false, action) => {

  switch(action.type) {
		case C.FETCHING :
			return true
		case C.END_FETCHING :
			return false

    default:
      return state
  }
}

export const units = (state=[], action) => {

  switch(action.type) {
    case C.CLEAR_UNITS :
      return []
    case C.STORE_UNITS :
      return action.payload
    default :
      return state
  }

}

export const standings = (state=[], action) => {

  switch(action.type) {
    case C.CLEAR_STANDINGS :
      return []
    case C.STORE_STANDINGS :
      return action.payload
    default :
      return state
  }
}

export default combineReducers({
  errors,
	allUnits: combineReducers({
		fetching,
		units
	}),
  standings: combineReducers({
    fetching,
    standings
  })
})
