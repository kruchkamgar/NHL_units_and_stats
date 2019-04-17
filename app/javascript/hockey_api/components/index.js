import Menu from './ui/Menu'
import ShowErrors from './containers/ShowErrors'
import { BrowserRouter, Route, Link} from 'react-router-dom'
import UnitsDisplay from './containers/UnitsDisplay'
import '../stylesheets/index.scss'

//first [UI/visible] action of app-- load this App from routes.js' '/' path
export const App = () =>
  <div>
    <HomePage/>
  </div>

const HomePage = () => (
  <div className="app">
    <div className="wrapper">
      { /*<ShowErrors /> */ }
      <Route path='/units' component={UnitsDisplay}/>
      <Route path='/' component={Menu}/>
    </div>
  </div>
)

export const Whoops404 = ({ match }) =>
    <div className="whoops-404">
        <h1>Whoops, route not found</h1>
        <p>Cannot find content for {match.path}</p>
    </div>
