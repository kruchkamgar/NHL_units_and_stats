import C from './constants'
import fetch from 'isomorphic-fetch'

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
