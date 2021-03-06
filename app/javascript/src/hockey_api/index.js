import C from './constants'
import React from 'react'
import { render } from 'react-dom'
import initData from './initialState.json'
import storeFactory from './store'
import { Provider } from 'react-redux'
import { BrowserRouter as Router, Switch, Route, Link } from 'react-router-dom'
import { App, Whoops404 } from './components/index'
import { addError } from './actions'

// local storage
const initialState = (localStorage["redux-store"]) ?
    JSON.parse(localStorage["redux-store"]) :
    initData

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
    <Router>
      <Switch>
        <Route path='/' component={App}/>
        <Route path="*" component={Whoops404}/>
      </Switch>
    </Router>
	</Provider>,
  document.getElementById('react-container') )
})
