import PropTypes from 'prop-types';

const PowerScoreRow = ({
  powerScore = {}
}) => {
  const scores = powerScore.scores[0]

  return (
    <tr id={powerScore.name}>
      <td> { powerScore.name } </td>
      <td> { scores.powerScore } </td>
      <td> { scores.pointsPercentageLatest } </td>
      <td> { scores.pointsPercentagePrior } </td>
      <td> { scores.asOfDate } </td>
    </tr>
  )
}

PowerScoreRow.propTypes = {
  powerScore: PropTypes.object.isRequired,
}

export default PowerScoreRow
