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

export const powerScores = (state=[], action) => {

  switch(action.type) {
    case C.CLEAR_POWERSCORES :
      return []
    case C.STORE_POWERSCORES :
      return action.payload
    default :
      return state
  }
}

export const schedule = (state=[], action) => {

  switch(action.type) {
    case C.CLEAR_SCHEDULE :
      return []
    case C.STORE_SCHEDULE :
      return action.payload
    default :
      return state
  }
}

export const scheduleDates = (state=[], action) => {

  switch(action.type) {
    case C.CLEAR_SCHEDULE_DATES :
      return []
    case C.STORE_SCHEDULE_DATES :
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
  powerScores: combineReducers({
    fetching,
    powerScores,
    schedule,
    scheduleDates
  })
})
