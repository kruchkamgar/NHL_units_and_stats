import PropTypes from 'prop-types';

const UnitRow = ({ html_id, players, tallies/*, id, created_at, instances, plus_minus*/ }) =>
    <tr id = {html_id}>
        <td>
            { players
              .map(name =>
                <div className="data-list">{name}</div> ) }
            { /*instances["players_names"]
              .map(name =>
                 <div className="data-list">{name}</div>) */}
        </td>
        <td>
            { tallies["plus_minus"] }
        </td>
        <td>

        </td>
    </tr>

UnitRow.propTypes = {
    /* date: PropTypes.string.isRequired,
    backcountry: PropTypes.bool,*/
    onRemoveDay: PropTypes.func
}

export default UnitRow
