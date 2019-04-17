import PropTypes from 'prop-types';
import { terrain } from 'react-icons/md'
import { snowflake } from 'react-icons/ti'

const SkiDayRow = ({ resort, date, powder, backcountry, onRemoveDay=f=>f }) =>
    <tr onDoubleClick={() => onRemoveDay(date)}>
        <td>
            {date}
        </td>
        <td>
            {resort}
        </td>
        <td>
            {(powder) ? <snowflake /> : null }
        </td>
        <td>
            {(backcountry) ? <terrain /> : null }
        </td>
    </tr>

SkiDayRow.propTypes = {
    resort: PropTypes.string.isRequired,
    date: PropTypes.string.isRequired,
    powder: PropTypes.bool,
    backcountry: PropTypes.bool,
    onRemoveDay: PropTypes.func
}

export default SkiDayRow
