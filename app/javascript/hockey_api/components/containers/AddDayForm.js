import AddDayForm from '../ui/AddDayForm'
import { withRouter } from 'react'
import { connect } from 'react-redux'
import { addDay, suggestResortNames, clearSuggestions } from '../../actions'

//setting props to
const mapStateToProps = (state, props) =>
	({
		suggestions: state.resortNames.suggestions,
		fetching: state.resortNames.fetching, // "resortNames.fetching" reducer
		router: props.router
	})

const mapDispatchToProps = dispatch =>
	({
		onNewDay({ resort, date, powder, backcountry }) {
			dispatch(
				addDay(resort, date, powder, backcountry)
			)
		},
		onChange(value) {
			if (value) {
				dispatch(
					suggestResortNames(value)
				)
			} else {
				dispatch(
					clearSuggestions()
				)
			}
		},
		onClear() {
			dispatch(
				clearSuggestions()
			)
		}
	})

const Container = connect(mapStateToProps, mapDispatchToProps)(AddDayForm)

export default Container
