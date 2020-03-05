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

export const standings = (latest=20) => dispatch => {
  dispatch({ type: C.FETCH_UNITS })

  fetch(
    '/standings')
  .then(response => response.json() )
  .then(standings => {
    dispatch({
      type: C.STORE_STANDINGS,
      payload: standings
    })
    dispatch({ type: C.END_FETCHING })
  })

}



export const clearUnits = () =>
  ({
    type: C.CLEAR_UNITS
  })

// export const units = () => dispatch => {
//
//     //stores fetching reducer as true
//     dispatch({ type: C.FETCHING })
//
//     fetch('/units')
//       .then(response => response.json())
//       .then(units => {
//           dispatch({
//               type: C.STORE_UNITS,
//               payload: units })
//           dispatch({ type: C.STORE })
//       })
//       .catch(error => {
//           dispatch(
//               addError(error.message)     )
//           dispatch({
//               type: C.CANCEL_FETCHING })
//       })
// }
export const team_units = (team_number) => dispatch => { // *1
    //stores fetching reducer as true
    dispatch({ type: C.FETCH_UNITS })

    fetch(`/units/${team_number}`)
      .then(response => response.json())
      .then(units => {
          dispatch({
              type: C.STORE_UNITS,
              payload: units })
          dispatch({ type: C.END_FETCHING }) //fetching: false
      })
      .catch(error => {
          dispatch(
              addError(error.message) )
          dispatch({
              type: C.CANCEL_FETCHING })
      })
}
