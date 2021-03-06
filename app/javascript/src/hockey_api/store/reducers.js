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
  	default:
  		return state
  }
}

// stored upon dispatch
export const fetching = (state=false, action) => {

  switch(action.type) {

    case C.CANCEL_FETCHING :
      return false

		case C.FETCH_UNITS :
			return true

		case C.STORE_UNITS :
			return true

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

export default combineReducers({
  errors,
	allUnits: combineReducers({
		fetching,
		units
	})
})
