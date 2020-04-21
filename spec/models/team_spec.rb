require 'rails_helper'

describe Team, type: :model do

  it "has validity" do
    expect(subject).to be_valid
  end

end
