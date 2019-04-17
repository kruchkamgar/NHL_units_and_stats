import C from './constants'
import React from 'react'
import { render } from 'react-dom'
import sampleData from './initialState.json'
import storeFactory from './store'
import { Provider } from 'react-redux'
import { BrowserRouter, Switch, Route, Link } from 'react-router-dom'
import { App, Whoops404 } from './components/index'
import SkiDayCount from './components/containers/SkiDayCount'
import { addError } from './actions'

// local storage
const initialState = (localStorage["redux-store"]) ?
    JSON.parse(localStorage["redux-store"]) :
    sampleData

const saveState = () =>
    localStorage["redux-store"] = JSON.stringify(store.getState())

const handleError = error => {
	store.dispatch(
		addError(error.message)
	) }

const store = storeFactory(initialState)
store.subscribe(saveState)

window.React = React
window.store = store

window.addEventListener("error", handleError)

document.addEventListener('DOMContentLoaded', () => {
render(
	<Provider store={store}>
    <BrowserRouter>
      <Switch>
        <Route path='/' component={App}/>
        <Route path='/' component={SkiDayCount}/>
        <Route path="*" component={Whoops404}/>
      </Switch>
    </BrowserRouter>
	</Provider>,
  document.getElementById('react-container') )
})
