import Menu from './ui/Menu'
import ShowErrors from './containers/ShowErrors'
import { Switch, Route, Redirect } from 'react-router-dom'
import UnitsDisplay from './containers/UnitsDisplay'
import PowerScoresDisplay from './containers/PowerScoresDisplay'
import 'stylesheets/index.scss'

export const App = () =>
  <div className="app">
    <FirstLevel/>
  </div>

const FirstLevel = () => (
    <div className="wrapper">
      { /*<ShowErrors /> */ }
      <Switch>
        <Route path='/units' component={UnitsDisplay}/>
        <Route path='/latest' component={PowerScoresDisplay}/>
        <Route exact path='/'>
          <Redirect to="/latest" /></Route>
      </Switch>
      <Route path='/teams' component={Menu}/>
    </div>
)

export const Whoops404 = ({ match }) =>
    <div className="whoops-404">
        <h1>Whoops, route not found</h1>
        <p>Cannot find content for {match.path}</p>
    </div>
