import PropTypes from 'prop-types';
import { calendar } from 'react-icons/fa'
import { terrain } from 'react-icons/md'
import { snowflake } from 'react-icons/ti'
import '../../stylesheets/SkiDayCount.scss'

const SkiDayCount = ({ total=0, powder=0, backcountry=0 }) =>
    <div className="ski-day-count">
        <div className="total-days">
            <span>{total}</span>
            <calendar />
            <span>days</span>
        </div>
        <div className="powder-days">
            <span>{powder}</span>
            <snowflake />
            <span>powder</span>
        </div>
        <div className="backcountry-days">
            <span>{backcountry}</span>
            <terrain />
            <span>hiking</span>
        </div>
    </div>

SkiDayCount.propTypes = {
    total: PropTypes.number,
    powder: PropTypes.number,
    backcountry: PropTypes.number
}

export default SkiDayCount
