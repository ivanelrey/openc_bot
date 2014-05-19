# encoding: UTF-8
require 'json-schema'
require 'active_support/core_ext'
require 'debugger'

describe 'company-schema' do
  before do
    @schema = File.join(File.dirname(__FILE__),'..','..','schemas','company-schema.json')
  end

  it "should validate simple company" do
    valid_company_params =
      [
        { :name => 'Foo Inc',
          :company_number => '12345',
          :jurisdiction_code => 'ie'
        },
        { :name => 'Foo Inc',
          :company_number => '12345',
          :jurisdiction_code => 'us_de',
          :registered_address => '32 Foo St, Footown,'
        }
      ]
      valid_company_params.each do |valid_params|
        errors = validate_datum_and_return_errors(valid_params)
        errors.should be_empty, "Valid params were not valid: #{valid_params}"
      end
  end

  it "should validate complex company" do
    valid_company_params =
      { :name => 'Foo Inc',
        :company_number => '12345',
        :jurisdiction_code => 'us_de',
        :incorporation_date => '2010-10-20',
        :dissolution_date => '2012-01-12'
      }
    errors = validate_datum_and_return_errors(valid_company_params)
    errors.should be_empty
  end

  it "should not validate invalid company" do
    invalid_company_params =
      [
        { :name => 'Foo Inc',
          :jurisdiction_code => 'ie'
        },
        { :name => 'Foo Inc',
          :jurisdiction_code => 'usa_de',
          :company_number => '12345'
        },
        { :name => 'Bar',
          :jurisdiction_code => 'us_de',
          :company_number => ''
        },
        { :name => 'Foo Inc',
          :jurisdiction_code => 'a',
          :company_number => '12345'
        },
        { :name => '',
          :jurisdiction_code => 'us_de',
          :company_number => '12345'
        },
        { :name => 'Foo Inc',
          :jurisdiction_code => 'us_de',
          :company_number => '12345',
          :foo => 'bar'
        }
    ]
    invalid_company_params.each do |invalid_params|
      errors = validate_datum_and_return_errors(invalid_params)
      errors.should_not be_empty, "Invalid params were not invalid: #{invalid_params}"
    end
  end

  context "and company has registered_address" do
    it "should be valid if it is a string" do
      valid_company_params =
        { :name => 'Foo Inc',
          :company_number => '12345',
          :jurisdiction_code => 'us_de',
          :registered_address => '32 Foo St, Footown,'
        }
      errors = validate_datum_and_return_errors(valid_company_params)
      errors.should be_empty
    end

    it "should be valid if it is nil" do
      valid_company_params =
        { :name => 'Foo Inc',
          :company_number => '12345',
          :jurisdiction_code => 'us_de',
          :registered_address => nil
        }
      errors = validate_datum_and_return_errors(valid_company_params)
      errors.should be_empty
    end

    it "should be valid if it is a valid address object" do
      valid_company_params =
        [
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'us_de',
            :registered_address => { :street_address => '32 Foo St', :locality => 'Footown', :region => 'Fooshire', :postal_code => 'FO1 2BA' }
          },
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'us_de',
            :registered_address => { :street_address => '32 Foo St' }
          },
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'us_de',
            :registered_address => { :postal_code => 'FO1 2BA' }
          }
        ]
        valid_company_params.each do |valid_params|
          errors = validate_datum_and_return_errors(valid_params)
          errors.should be_empty, "Valid params were not valid: #{valid_params}.Errors = #{errors}"
        end
    end

    it "should not be valid if it is not a valid address object" do
      invalid_company_params =
        [
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :registered_address => []
          },
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :registered_address => ''
          },
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :registered_address => {:country => 'Germany'}
          },
          # { :name => 'Foo Inc',
          #   :company_number => '12345',
          #   :jurisdiction_code => 'us_de',
          #   :registered_address => {:country => 'Germany'}
          # }
        ]
      invalid_company_params.each do |invalid_params|
        errors = validate_datum_and_return_errors(invalid_params)
        errors.should_not be_empty, "Invalid params were not invalid: #{invalid_params}"
      end
    end
  end

  context "and company has previous names" do
    it "should validate valid previous names data" do
      valid_company_params =
        [
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :previous_names => [{:company_name => 'FooBar Inc'},
                                {:company_name => 'FooBaz', :con_date => '2012-07-22'},
                                {:company_name => 'FooBaz', :con_date => '2012-07-22', :start_date => '2008-01-08'}]
          },
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            # allow empty arrays
            :previous_names => []
          }
        ]
      valid_company_params.each do |valid_params|
        errors = validate_datum_and_return_errors(valid_params)
        errors.should be_empty, "Valid params were not valid: #{valid_params}"
      end
    end

    it "should not validated invalid previous names data" do
      invalid_company_params =
        [
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :previous_names => 'some name'
          },
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :previous_names => ['some name']
          },
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :previous_names => [{:name => 'Baz Inc'}]
          },
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :previous_names => [{:company_name => ''}]
          }
        ]

      invalid_company_params.each do |invalid_params|
        errors = validate_datum_and_return_errors(invalid_params)
        errors.should_not be_empty, "Invalid params were not invalid: #{invalid_params}"
      end

    end
  end

  context "and company has branch flag" do
    it "should be valid if it is F or L or nil" do
      valid_company_params =
        [
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :branch => 'F'
          },
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'us_de',
            :branch => 'L'
          },
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'us_de',
            :branch => nil
          }
        ]
        valid_company_params.each do |valid_params|
          errors = validate_datum_and_return_errors(valid_params)
          errors.should be_empty, "Valid params were not valid: #{valid_params}.Errors = #{errors}"
        end

    end

    it "should not be valid if it is not F or L" do
      invalid_company_params =
        [
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :branch => 'X'
          },
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :branch => 'FOO'
          },
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'us_de',
            :branch => ''
          }
        ]
        invalid_company_params.each do |invalid_params|
          errors = validate_datum_and_return_errors(invalid_params)
          errors.should_not be_empty, "Invalid params were not invalid: #{invalid_params}"
        end

    end
  end

  context "and company has all_attributes" do
    it "should allow arbitrary elements to all_attributes hash" do
      valid_company_params =
        [
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :all_attributes => {:foo => 'bar', :some_number => 42, :an_array => [1,2,3]}
          },
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'us_de',
            :all_attributes => {}
          }
        ]
        valid_company_params.each do |valid_params|
          errors = validate_datum_and_return_errors(valid_params)
          errors.should be_empty, "Valid params were not valid: #{valid_params}.Errors = #{errors}"
        end
    end

    it "should require jurisdiction_of_origin to be a non-empty string or null" do
      valid_params_1 =
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :all_attributes => {:jurisdiction_of_origin => 'Some Country'}
          }
      valid_params_2 =
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :all_attributes => {:jurisdiction_of_origin => nil}
          }
      invalid_params_1 =
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :all_attributes => {:jurisdiction_of_origin => ''}
          }
      invalid_params_2 =
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :all_attributes => {:jurisdiction_of_origin => 43}
          }
      validate_datum_and_return_errors(valid_params_1).should be_empty
      validate_datum_and_return_errors(valid_params_2).should be_empty
      validate_datum_and_return_errors(invalid_params_1).should_not be_empty
      validate_datum_and_return_errors(invalid_params_2).should_not be_empty
    end

    it "should require registered_agent_name to be a string" do
      valid_params =
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :all_attributes => {:registered_agent_name => 'Some Person'}
          }
      invalid_params_1 =
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :all_attributes => {:registered_agent_name => ''}
          }
      invalid_params_2 =
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :all_attributes => {:registered_agent_name => 43}
          }
      validate_datum_and_return_errors(valid_params).should be_empty
      validate_datum_and_return_errors(invalid_params_1).should_not be_empty
      validate_datum_and_return_errors(invalid_params_2).should_not be_empty
    end

    it "should require registered_agent_address to be a string" do
      valid_params =
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :all_attributes => {:registered_agent_address => 'Some Address'}
          }
      invalid_params_1 =
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :all_attributes => {:registered_agent_address => ''}
          }
      invalid_params_2 =
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :all_attributes => {:registered_agent_address => 43}
          }
      validate_datum_and_return_errors(valid_params).should be_empty
      validate_datum_and_return_errors(invalid_params_1).should_not be_empty
      validate_datum_and_return_errors(invalid_params_2).should_not be_empty
    end

    it "should require number_of_employees to be an positive" do
      valid_params =
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :all_attributes => {:number_of_employees => 42}
          }
      invalid_params_1 =
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :all_attributes => {:number_of_employees => ''}
          }
      invalid_params_2 =
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :all_attributes => {:number_of_employees => 'foo'}
          }
      invalid_params_3 =
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :all_attributes => {:number_of_employees => -1}
          }
      validate_datum_and_return_errors(valid_params).should be_empty
      validate_datum_and_return_errors(invalid_params_1).should_not be_empty
      validate_datum_and_return_errors(invalid_params_2).should_not be_empty
      validate_datum_and_return_errors(invalid_params_3).should_not be_empty
    end
  end

  context "and company has officers" do
    it "should validate if officers are valid" do
      valid_company_params =
        [
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :officers => [{:name => 'Fred Flintstone'},
                          {:name => 'Barney Rubble', :position => 'Director'},
                          {:name => 'Barney Rubble', :other_attributes => {:foo => 'bar'}},
                          {:name => 'Pebbles', :start_date => '2010-12-22', :end_date => '2011-01-03'}]
          },
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            # allow empty arrays
            :officers => []
          }
        ]
        valid_company_params.each do |valid_params|
          errors = validate_datum_and_return_errors(valid_params)
          errors.should be_empty, "Valid params were not valid: #{valid_params}"
        end
    end

    it "should not validate if officers are not valid" do
      invalid_company_params =
        [
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :officers => [{:name => ''}]
          },
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :officers => [{:position => 'Director'}]
          },
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :officers => 'some body'
          },
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :officers => [{:name => 'Fred',  :other_attributes => 'non object'}]
          },
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :officers => ['some body']
          }
        ]
      invalid_company_params.each do |invalid_params|
        errors = validate_datum_and_return_errors(invalid_params)
        errors.should_not be_empty, "Invalid params were not invalid: #{invalid_params}"
      end
    end
  end

  context "and company has filings" do
    it "should validate if filings are valid" do
      valid_company_params =
        [
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :filings => [ {:title => 'Annual Report', :date => '2010-11-22'},
                          {:description => 'Another type of filing', :date => '2010-11-22'},
                          {:title => 'Annual Report', :description => 'Another type of filing', :uid => '12345A321', :date => '2010-11-22'},
                          {:filing_type_name => 'Some type', :date => '2010-11-22'}]
          },
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :filings => [ {:title => 'Annual Report', :date => '2010-11-22', :other_attributes => {:foo => 'bar'}},
                          {:filing_type_name => 'Some type', :filing_type_code => '10-K', :date => '2010-11-22'}]
          },
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            # allow empty arrays
            :filings => []
          }
        ]
        valid_company_params.each do |valid_params|
          errors = validate_datum_and_return_errors(valid_params)
          errors.should be_empty, "Valid params were not valid: #{valid_params}.Errors = #{errors}"
        end
    end

    it "should not validate if filings are not valid" do
      invalid_company_params =
        [
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :filings => [ {:filing_type_name => 'Some type'}]
          },
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :filings => 'foo filing'
          },
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :filings => ['foo filing']
          }
        ]
      invalid_company_params.each do |invalid_params|
        errors = validate_datum_and_return_errors(invalid_params)
        errors.should_not be_empty, "Invalid params were not invalid: #{invalid_params}"
      end
    end

    it "should require either title or description or filing_type_name to be present" do
      valid_company_params =
        [
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :filings => [ {:filing_type_name => 'Some type', :date => '2010-11-22'}]
          },
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :filings => [ {:description => 'Some type', :date => '2010-11-22'}]
          },
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :filings => [ {:title => 'Some type', :date => '2010-11-22'}]
          }
        ]
      invalid_params =
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :filings => [ {:uid => '12345', :date => '2010-11-22'}]
          }
      valid_company_params.each do |valid_params|
        errors = validate_datum_and_return_errors(valid_params)
        errors.should be_empty, "Valid params were not valid: #{valid_params}.Errors = #{errors}"
      end

      validate_datum_and_return_errors(invalid_params).should_not be_empty
    end
  end

  context "and company has share_parcels" do
    it "should validate if share_parcels are valid" do
      valid_company_params =
        [
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :share_parcels =>
              [ { :number_of_shares => 1234,
                  :shareholders => [ {:name => 'Fred Flintstone'} ],
                  :confidence => 42
                 },
                { :percentage_of_shares => 23.5,
                  :shareholders => [ {:name => 'Barney Rubble'},
                                     {:name => 'Wilma Flintstone'} ]
                },
              ]
          },
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            # allow empty arrays
            :share_parcels => []
          }
        ]
        valid_company_params.each do |valid_params|
          errors = validate_datum_and_return_errors(valid_params)
          errors.should be_empty, "Valid params were not valid: #{valid_params}.Errors = #{errors}"
        end
    end

    it "should not validate if share_parcels are not valid" do
      invalid_company_params =
        [
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :share_parcels =>
             [{ :percentage_of_shares => '23.5',
                :shareholders => [ {:name => ''} ]}]
          },
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :share_parcels =>
             [{ :percentage_of_shares => '23.5',
                :shareholders => []}]
          },
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :share_parcels =>
             [{ :percentage_of_shares => '23.5'}]
          },
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :share_parcels => 'foo filing'
          },
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :share_parcels => ['foo filing']
          }
        ]
      invalid_company_params.each do |invalid_params|
        errors = validate_datum_and_return_errors(invalid_params)
        errors.should_not be_empty, "Invalid params were not invalid: #{invalid_params}"
      end
    end
  end

  context "and company has total_shares" do
    it "should validate if total_shares are valid" do
      valid_company_params =
        [
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :total_shares =>
             { :number => 123,
               :share_class => 'Ordinary' }
          },
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :total_shares =>
             { :number => 123 }
          }
        ]
        valid_company_params.each do |valid_params|
          errors = validate_datum_and_return_errors(valid_params)
          errors.should be_empty, "Valid params were not valid: #{valid_params}.Errors = #{errors}"
        end
    end

    it "should not validate if share_parcels are not valid" do
      invalid_company_params =
        [
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :total_shares =>
             { :share_class => 'Ordinary' }
          },
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :total_shares =>
             { :number => 123,
               :share_class => '' }
          },
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :total_shares => 'foo filing'
          },
          { :name => 'Foo Inc',
            :company_number => '12345',
            :jurisdiction_code => 'ie',
            :total_shares => ['foo filing']
          }
        ]
      invalid_company_params.each do |invalid_params|
        errors = validate_datum_and_return_errors(invalid_params)
        errors.should_not be_empty, "Invalid params were not invalid: #{invalid_params}"
      end
    end
  end

  def validate_datum_and_return_errors(record)
    errors = JSON::Validator.fully_validate(
      @schema,
      record.to_json,
      {:errors_as_objects => true})
  end

end