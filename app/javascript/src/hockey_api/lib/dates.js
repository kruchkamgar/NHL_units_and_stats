import { numDigits } from 'src/hockey_api/lib/utilities';

export const gamesByDates = (prevGames, dates, schedule, direction) => {
  let newGames = prevGames
  if (direction === -1) {
    newGames.unshift(
      schedule
      .filter( _date =>{
        Number(new Date(_date.date)) === Number(dates.previous)
      }).games )
    newGames.pop()
  } else if (direction === 1){
    newGames.push(
      schedule
      .filter( _date =>{
        Number(new Date(_date.date)) === Number(dates.subsequent)
      }).games )
    newGames.shift()
  } else {
    newGames =
    ['previous', 'day', 'subsequent']
    .map( day =>{
      return schedule.dates
        .find( _date =>
          _date.date === dates[day] ).games
    })
  }

  return newGames
}

export const gameDates = (scheduleDates, date) => {
  const dateIndex =
  scheduleDates
    .findIndex( _date => {
      return Number(new Date(_date)) === Number(date) });

  return {
    previous: scheduleDates[dateIndex-1],
    day: scheduleDates[dateIndex],
    subsequent: scheduleDates[dateIndex+1] };
}

export const addDays = (date, days) => {
  const summation = new Date(Number(date));
  summation
  .setDate(date.getDate() + days)
  return summation
}

export const dateString = (date) => {

  return `${date.getFullYear()}-${
    numDigits(date.getMonth()+1, 2)
  }-${
    numDigits(date.getDate()+1, 2)}`;
}
