import { NavLink, Link } from 'react-router-dom'
import { FaHome } from 'react-icons/fa'
import { FaCalendarPlusO } from 'react-icons/fa'
import { FaCalendar, FaTh } from 'react-icons/fa'
import 'stylesheets/Menu.scss'

const Menu = () =>
    <nav className="menu">
        {/*<NavLink to="/" activeClassName="selected">
           <FaHome />
        </NavLink> */}
        {/*
        // <NavLink to="/" activeClassName="selected">
        //     <FaCalendarPlusO />
        // </NavLink> */}
        <NavLink to="/latest" activeClassName="selected">
            <FaCalendar />
        </NavLink>
        <NavLink to="/units" activeClassName="selected">
            <FaTh />
        </NavLink>
    </nav>

export default Menu
