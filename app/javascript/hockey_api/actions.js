import C from './constants'
import fetch from 'isomorphic-fetch'

export function addDay(resort, date, powder=false, backcountry=false) {

    return {
        type: C.ADD_DAY,
        payload: {resort,date,powder,backcountry}
    }
}

export const removeDay = function(date) {
    return {
        type: C.REMOVE_DAY,
        payload: date
    }
}

export const setGoal = (goal) =>
    ({
        type: C.SET_GOAL,
        payload: goal
    })

export const addError = (message) =>
   ({
      type: C.ADD_ERROR,
      payload: message
   })

export const clearError = index =>
    ({
        type: C.CLEAR_ERROR,
        payload: index
    })

export const changeSuggestions = suggestions =>
  ({
    type: C.CHANGE_SUGGESTIONS,
    payload: suggestions
  })

export const clearSuggestions = () =>
    ({
        type: C.CLEAR_SUGGESTIONS
    })


export const suggestResortNames = value => dispatch => { // *1

    //stores fetching reducer as true
    dispatch({
        type: C.FETCH_RESORT_NAMES    })

    fetch('http://localhost:3333/resorts/' + value)
        .then(response => response.json())
        .then(suggestions => {
            dispatch({
                type: C.CHANGE_SUGGESTIONS,
                payload: suggestions    })
        })
        .catch(error => {
            dispatch(
                addError(error.message)    )
            dispatch({
                type: C.CANCEL_FETCHING   })
        })
}

export const clearUnits = () =>
  ({
    type: C.CLEAR_UNITS
  })

export const units = () => dispatch => { // *1

    //stores fetching reducer as true
    dispatch({
        type: C.FETCH_UNITS
    })

    fetch('/units')
      .then(response => response.json())
      .then(units => {
          dispatch({
              type: C.STORE_UNITS,
              payload: units            })
      })
      .catch(error => {
          dispatch(
              addError(error.message)     )
          dispatch({
              type: C.CANCEL_FETCHING    })
      })
}
export const team_units = (team_number) => dispatch => { // *1

    //stores fetching reducer as true
    dispatch({
        type: C.FETCH_UNITS
    })

    fetch(`/units/${team_number}`)
      .then(response => response.json())
      .then(units => {
          dispatch({
              type: C.STORE_UNITS,
              payload: units            })
      })
      .catch(error => {
          dispatch(
              addError(error.message)     )
          dispatch({
              type: C.CANCEL_FETCHING    })
      })
}



//*1-
//thunk allows this dispatch (and state), passed as higher-order function
