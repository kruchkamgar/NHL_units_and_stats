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

export const clearErrors = () =>
    ({ type: C.CLEAR_ERRORS })

export const standings = () => dispatch => {
  dispatch({ type: C.FETCHING })

  fetch('/teams')
  .then(response => response.json() )
  .then(standings_ => {
    dispatch({
      type: C.STORE_STANDINGS,
      payload: standings_
    })
    dispatch({ type: C.END_FETCHING })
  })
  .catch(error => {
      dispatch(
          addError(error.message) )
      dispatch({
          type: C.END_FETCHING })
  })

}

export const clearUnits = () =>
  ({
    type: C.CLEAR_UNITS
  })

export const team_units = (team_number) => dispatch => { // *1
    //stores fetching reducer as true
    dispatch({ type: C.FETCHING })

    fetch(`/units/${team_number}`)
      .then(response => response.json())
      .then(units => {
          dispatch({
              type: C.STORE_UNITS,
              payload: units })
          dispatch({
            type: C.END_FETCHING }) //fetching: false
      })
      .catch(error => {
          dispatch(
              addError(error.message) )
          dispatch({
              type: C.END_FETCHING })
      })
}
