import Day from './Day';
import { useState, useEffect } from 'react';

import { gameDates, gamesByDates, addDays, dateString } from 'src/hockey_api/lib/dates';

const PowerScoresDisplay = ({
  powerScoresByDate = [],
  schedule = [],
  scheduleDates = [],
  getScheduleAndPowerScores = f=>f,
  fetching = false,
  range = 5
}) => {

  const today = dateString(new Date());
  const [timeMark, setTimeMark] = useState("2020-03-04");
  // when (request - timeMark) == 4 || == 0 and direction == 1, make new request
  const [request, setRequest] = useState(timeMark);
    // could put condition in action creator
    if(!fetching && (
      powerScoresByDate.length === 0 || schedule.length === 0 ||
      direction == 1) ) getScheduleAndPowerScores(timeMark);

  // use to determine, when next to fetch
  const [trackDays, setTrackDays] = useState(5);
  const [dates, setDates] = useState();

  let direction = 0;
  const [games, setGames] = useState({
    previous: [], day:[], subsequent:[]
  });
  const [powerScoresPerDay, setPowerScoresPerDay] = useState([]);

useEffect( ()=> {
  if(scheduleDates.length > 0){
    // days based on schedule
    setDates(
      gameDates(scheduleDates, timeMark, direction) );
  }
}, [timeMark, scheduleDates]); // useEffect

useEffect( ()=> {
  if(!(dates === undefined)){
    // find the latest powerScores using the timeMark
    setPowerScoresPerDay(
      Object.keys(dates)
      .map( dateKey => {
        return powerScoresByDate
        .find( score => score.date == dates[dateKey] ) })
    )

    // - function to collect games from schedule matching the date
// performance, logic: do this on the server side, by keeping powerScoresByDate in schedule format.
// - (pull all needed game data like 'home, away', there)
    setGames( prevGames=>{
      return gamesByDates(prevGames, dates, schedule, direction)
    });
  } //if
}, [dates])

  // const compareTimeMarks =
  // (prevTimeMark) => {
  //   let direction = 0;
  //   if (prevTimeMark < timeMark) direction = 1;
  //   if (prevTimeMark > timeMark) direction = -1;
  //   return direction;
  // }

  // - click handler function to move between days
  const setTimeMark_ = (_direction) => {
    direction = _direction;
    setTimeMark( prevTimeMark => {
      // direction = compareTimeMarks(prevTimeMark)
      return addDays(prevTimeMark, direction) })
  }

  const handleDateChange =
  (_direction) => {

    if (_direction === "increment") {
      nextDay.props.games ? setTimeMark_(1) : null; // check server for more games instead (call getScheduleAndPowerScores() with the timeMark+range date.  )
      // - modify the action to append new games
    }
    else { setTimeMark_(-1); }
  }

  // to animate:
  // - use placeholder days instead, or create a new one (document.createElement...)
  // - increment the games array number modulo 3 (3 mod 2+1 = 0) and unshift the previous day's games
  const previousDay = <Day games={games[0]} dayScores={false}/>;

  const currentDay = powerScoresPerDay[1] ? <Day games={games[1]}
    dayScores={powerScoresPerDay[1]}/> : null;
  const nextDay = <Day games={games[2]} dayScores={false}/>;
  //

  return (
    <div className="wrapper d-flex">
      <div className="queued chart" onClick={ ()=>
        handleDateChange("decrement")}>{previousDay}</div>
      <div className="queue chart">
        {currentDay}</div>
      <div className="queued chart" onClick={ ()=>
        handleDateChange("increment")}>{nextDay}</div>
    </div>
  )
}

export default PowerScoresDisplay

// LOGOS-
// http://www-league.nhlstatic.com/images/logos/teams-current-primary-dark/${teamId}.svg
