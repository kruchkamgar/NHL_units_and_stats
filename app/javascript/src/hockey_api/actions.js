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


const scheduleDates = (schedule) => {
  return schedule.dates
    .map( date=> date.date )
}

export const scheduleAndPowerScores = (date) => dispatch => {
  dispatch({ type: C.FETCHING })

  fetch(`/power_scores?days=5&date=${date}`)
  .then(response => response.json() )
  .then(scheduleAndPowerScores => {
    dispatch({
      type: C.STORE_POWERSCORES,
      payload: scheduleAndPowerScores.powerScores
    })
    dispatch({
      type: C.STORE_SCHEDULE,
      payload: scheduleAndPowerScores.schedule
    })
    dispatch({
      type: C.STORE_SCHEDULE_DATES,
      payload: scheduleDates(scheduleAndPowerScores.schedule)
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

export const teamUnits = (teamNumber) => dispatch => { // *1
    //stores fetching reducer as true
    dispatch({ type: C.FETCHING })

    fetch(`/units/${teamNumber}`)
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
