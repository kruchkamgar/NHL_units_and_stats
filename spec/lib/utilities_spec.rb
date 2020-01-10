require 'utilities'

describe Utilities do

  describe 'TimeOperation' do

    it 'evaluates operations for standard time string' do
      time = Utilities::TimeOperation.new(:+,
        [ "3:00", "1:33" ]).result

      expect(time).to eq("04:33")
    end

    it 'evaluates operations for \'yyyymmdd_hhmmss\'' do
      time = Utilities::TimeOperation.new(:+,
        [ { time: "20191117_052923", format: "yyyymmdd_hhmmss" },
          "1:33" ]).result

      expect(time).to eq("05:30:56")
    end

    it 'evaluates operations for \'TZ\'' do
      time = Utilities::TimeOperation.new(:-,
        [ { time: "2019-11-17T05:31:28Z", format: "TZ" },
          "1:33" ]).result

      expect(time).to eq("05:29:55")
    end

  end # TimeOperation
end # Utilities
