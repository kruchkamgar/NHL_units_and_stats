import Day from './Day';
import { useState, useReducer, useEffect } from 'react';

import { gameDates, gamesByDates, addDays, dateString } from 'src/hockey_api/lib/dates';

const PowerScoresDisplay = ({
  powerScoresByDate = [],
  schedule = [],
  scheduleDates = [],
  getScheduleAndPowerScores = f=>f,
  fetching = false,
  scheduleDays = 5
}) => {

  const today = dateString(new Date());
  const [timeMark, setTimeMark] = useState("2020-03-04");

    // could put condition in action creator
    if(!fetching && (
      powerScoresByDate.length === 0 || schedule.length === 0 ||
      direction === 1) ) getScheduleAndPowerScores(timeMark);

  let direction = 0;
  // triggers setGames, could merely call setGames from 'handleDateChange'
  const [dates, setDates] = useState(
    gameDates(scheduleDates, timeMark, direction) );

  const [games, setGames] = useState({
    previous: [], day:[], subsequent:[]
  })
  const [powerScoresPerDay, setPowerScoresPerDay] = useState([]);
  const [days, daysDispatch] = useReducer(daysReducer, { previous: null, day: null, subsequent: null })

  function daysReducer(state, action) {
    switch(action.type) {
      case 'update' :
        return action.payload
      default :
        throw new Error()
    }
  }

useEffect( ()=> {
  !fetching &&
  !(powerScoresByDate.length === 0) &&
  !powerScoresByDate.find( score => score.date === dates.previous) ?
    getScheduleAndPowerScores(dates.previous, false) : null;

  console.log("previous pScore", !powerScoresByDate.find( score => score.date === dates.previous) );
}, [dates])

useEffect( ()=> {
  console.log("dates or powerScoresByDate");
  if(!(dates === undefined)){
    // find the latest powerScores using the dates
    setPowerScoresPerDay(
      Object.keys(dates)
      .map( dateKey => {
        return powerScoresByDate
        .find( score => score.date == dates[dateKey] ) })
    )

    // - function to collect games from schedule matching the date
// performance, logic: do this on the server side, by keeping powerScoresByDate in schedule format.
// - (pull all needed game data like 'home, away', there)
  } //if
}, [dates, powerScoresByDate])

useEffect( ()=> {
  schedule.length > 0 ?
    setGames( prevGames=>{
      return gamesByDates(prevGames, dates, schedule, direction)
    }) : null

  direction = 0;
}, [dates, schedule])

useEffect( ()=> {
  if(!(dates === undefined)){
    daysDispatch({
      type: 'update',
      payload: {
        previous: <Day date={dates.previous} games={games[0]} dayScores={false}/>,
        day: powerScoresPerDay[1] ?
          <Day date={dates.day} games={games[1]} dayScores={powerScoresPerDay[1]}/> : null,
        subsequent: <Day date={dates.subsequent} games={games[2]} dayScores={false}/> }
    }) // daysDispatch
  } // if
}, [games])

// useEffect( () => {
//   console.log("reducer updates");
//   console.log("days.previous", days.previous);
// }, [days])

  // - click handler function to move between days
  // const setTimeMark_ =
  // (_direction) => {
  //   direction = _direction;
  //   setTimeMark( prevTimeMark => {
  //     // direction = compareTimeMarks(prevTimeMark)
  //     return addDays(prevTimeMark, direction) })
  // }

  const handleDateChange =
  (_direction) => {
    direction = _direction === "increment" ? 1 : -1;

    if (_direction === "increment") {
      // could also use a 'scheduleDatesIndex' variable, set automatically or tracked
      days.subsequent.props.games ?
        setDates( gameDates(scheduleDates, dates.subsequent) ) : null; // check server for more games instead (call getScheduleAndPowerScores() with the timeMark+range date.  )
      // - modify the action to append new games
    }
    else {
      setDates( gameDates(scheduleDates, dates.previous) )
    }
  }

  // to animate:
  // - use placeholder days instead, or create a new one (document.createElement...)
  // - increment the games array number modulo 3 (3 mod 2+1 = 0) and unshift the previous day's games
  //

  return (
    <div className="wrapper d-flex">
      <div className="queued chart" onClick={ ()=>
        handleDateChange("decrement")}>{days.previous}</div>
      <div className="queue chart">
        {days.day}</div>
      <div className="queued chart" onClick={ ()=>
        handleDateChange("increment")}>{days.subsequent}</div>
    </div>
  )
}

export default PowerScoresDisplay

// LOGOS-
// http://www-league.nhlstatic.com/images/logos/teams-current-primary-dark/${teamId}.svg
