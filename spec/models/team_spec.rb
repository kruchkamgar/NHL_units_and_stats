require 'rails_helper'

RSpec.describe Team, type: :model do

  it "has validity" do
    expect(subject).to be_valid
  end

end
