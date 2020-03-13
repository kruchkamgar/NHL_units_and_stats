import React from 'react';
import PropTypes from 'prop-types';

const StandingRow = ({
  standing = []
}) =>
    <tr id={standing[0]}>
        <td> { standing[0] } </td>
        <td> { standing[1] } </td>
    </tr>

StandingRow.propTypes = {
  standing: PropTypes.array.isRequired,
}

export default StandingRow
