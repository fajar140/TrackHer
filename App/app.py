from flask import Flask, request, jsonify, session
from flask_mysqldb import MySQL
from flask_cors import CORS
from werkzeug.security import generate_password_hash, check_password_hash
import joblib
from sklearn.preprocessing import StandardScaler
import pandas as pd


app = Flask(__name__)
CORS(app)  # Enable CORS for the entire app
app.secret_key = 'your_secret_key'  # Set a secret key for session management

app.config['MYSQL_HOST'] = 'localhost'
app.config['MYSQL_USER'] = 'root'
app.config['MYSQL_PASSWORD'] = ''
app.config['MYSQL_DB'] = 'trackher_app'

mysql = MySQL(app)

@app.route('/signup', methods=['POST'])
def signup():
    data = request.get_json()
    email = data['email']
    password = data['password']
    hashed_password = generate_password_hash(password, method='pbkdf2:sha256')

    cursor = mysql.connection.cursor()
    try:
        cursor.execute('INSERT INTO users (email, password) VALUES (%s, %s)', (email, hashed_password))
        mysql.connection.commit()
        return jsonify({'message': 'User registered successfully'})
    except Exception as e:
        mysql.connection.rollback()
        return jsonify({'error': str(e)}), 400
    finally:
        cursor.close()

@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    email = data['email']
    password = data['password']

    cursor = mysql.connection.cursor()
    cursor.execute('SELECT id, email, password FROM users WHERE email = %s', (email,))
    user = cursor.fetchone()
    cursor.close()

    if user and check_password_hash(user[2], password):
        session['user_id'] = user[0]
        session['email'] = user[1]
        return jsonify({'message': 'Login successful', 'user': {'id': user[0], 'email': user[1]}})
    return jsonify({'message': 'Invalid email or password'}), 401

@app.route('/verify_email', methods=['POST'])
def verify_email():
    data = request.get_json()
    email = data.get('email')

    cursor = mysql.connection.cursor()
    cursor.execute('SELECT id FROM users WHERE email = %s', (email,))
    user = cursor.fetchone()
    cursor.close()

    if user:
        return jsonify({'status': 'success', 'message': 'Email is registered'})
    else:
        return jsonify({'status': 'error', 'message': 'Email not found'}), 404
    
@app.route('/change_password', methods=['POST'])
def change_password():
    # Get data from the request
    data = request.get_json()

    # Debugging print statements to check the data
    print(f"Received data: {data}")

    email = data.get('email')
    new_password = data.get('new_password')

    # Check if the email and new password are provided
    if not email or not new_password:
        return jsonify({'error': 'Email and new password are required'}), 400

    # Print out the email for debugging
    print(f"Email received: {email}")

    # Hash the new password before storing it
    hashed_password = generate_password_hash(new_password, method='pbkdf2:sha256')

    # Initialize cursor to interact with the database
    cursor = mysql.connection.cursor()
    try:
        # Check if the email exists in the database
        cursor.execute('SELECT * FROM users WHERE email = %s', (email,))
        user = cursor.fetchone()

        # If user is not found
        if not user:
            return jsonify({'error': 'No user found with this email'}), 404

        # Execute the update query
        cursor.execute('UPDATE users SET password = %s WHERE email = %s', (hashed_password, email))

        # Commit the changes to the database
        mysql.connection.commit()

        # Return success message
        return jsonify({'message': 'Password updated successfully'}), 200
    except Exception as e:
        # Rollback in case of an error
        mysql.connection.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        # Close the cursor after the operation
        cursor.close()


@app.route('/user', methods=['GET'])
def get_user():
    email = request.args.get('email')
    print(f'Requested email: {email}')  # Debug: Check the email received in the request

    cursor = mysql.connection.cursor()
    cursor.execute('SELECT id, email, password FROM users WHERE email = %s', (email,))
    user = cursor.fetchone()
    cursor.close()

    if user:
        user_data = {
            'id': user[0],
            'email': user[1],
        }
        print(f'User data: {user_data}')  # Debug: Check the user data retrieved from the database
        return jsonify(user_data)
    else:
        return jsonify({'message': 'User not found'}), 404

# Load the model
model = joblib.load('trained_rf_model.pkl')

# Initialize the scaler
scaler = joblib.load('scaler.pkl')

@app.route('/predict', methods=['POST'])
def predict():
    try:
        # Extract data from the POST request
        data = request.get_json()
        email = data.get('email')
        
        if not email:
            return jsonify({'message': 'Email is required'}), 400

        cursor = mysql.connection.cursor()
        cursor.execute('SELECT id FROM users WHERE email = %s', (email,))
        user = cursor.fetchone()
        cursor.close()

        if not user:
            return jsonify({'message': 'User not found'}), 404
        
        user_id = user[0]

        # Retrieve input values
        reproductive_category = data['ReproductiveCategory']
        group = data['Group']
        cycle_with_peak_or_not = data['CycleWithPeakorNot']
        length_of_luteal_phase = data['LengthofLutealPhase']
        length_of_menses = data['LengthofMenses']
        total_menses_score = data['TotalMensesScore']
        number_of_days_of_intercourse = data['NumberofDaysofIntercourse']
        intercourse_in_fertile_window = data['IntercourseInFertileWindow']
        unusual_bleeding = data['UnusualBleeding']

        # Create DataFrame with the input data
        input_data = pd.DataFrame({
            'ReproductiveCategory': [reproductive_category],
            'Group': [group],
            'CycleWithPeakorNot': [cycle_with_peak_or_not],
            'LengthofLutealPhase': [length_of_luteal_phase],
            'LengthofMenses': [length_of_menses],
            'TotalMensesScore': [total_menses_score],
            'NumberofDaysofIntercourse': [number_of_days_of_intercourse],
            'IntercourseInFertileWindow': [intercourse_in_fertile_window],
            'UnusualBleeding': [unusual_bleeding]
        })

        # Scale the input data
        scaled_input_data = scaler.transform(input_data)

        # Make predictions
        predictions = model.predict(scaled_input_data)
        rounded_length, predicted_ovulation = predictions[0]

        # Round predictions
        rounded_length = round(rounded_length)
        predicted_ovulation = round(predicted_ovulation)

        # Save prediction to the database
        cursor = mysql.connection.cursor()
        cursor.execute('''
                       INSERT INTO prediction (
                       id, reproductive_category, `group`, cycle_with_peak_or_not, 
                       length_of_luteal_phase, length_of_menses, total_menses_score, 
                       number_of_days_of_intercourse, intercourse_in_fertile_window, 
                       unusual_bleeding, rounded_length, predicted_ovulation
                       ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                       ''', (
                           user_id, reproductive_category, group, cycle_with_peak_or_not,
                           length_of_luteal_phase, length_of_menses, total_menses_score, 
                           number_of_days_of_intercourse, intercourse_in_fertile_window, 
                           unusual_bleeding, rounded_length, predicted_ovulation
                       ))

        mysql.connection.commit()
        cursor.close()

        return jsonify({
            'rounded_length': rounded_length,
            'predicted_ovulation': predicted_ovulation
        })
    
    except Exception as e:
        return jsonify({'error': str(e)}), 400
        
@app.route('/delete_prediction', methods=['POST'])
def delete_prediction():
    try:
        data = request.get_json()
        email = data.get('email')
        
        if not email:
            return jsonify({'message': 'Email is required'}), 400

        cursor = mysql.connection.cursor()
        cursor.execute('SELECT id FROM users WHERE email = %s', (email,))
        user = cursor.fetchone()

        if not user:
            return jsonify({'message': 'User not found'}), 404
        
        user_id = user[0]

        # Delete prediction based on user_id
        cursor.execute('DELETE FROM prediction WHERE id = %s', (user_id,))
        mysql.connection.commit()
        cursor.close()

        return jsonify({'message': 'Prediction deleted successfully.'})
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    
@app.route('/get_prediction', methods=['GET'])
def get_prediction():
    email = request.args.get('email')
    if not email:
        return jsonify({'message': 'Email is required'}), 400

    cursor = mysql.connection.cursor()
    cursor.execute('SELECT id FROM users WHERE email = %s', (email,))
    user = cursor.fetchone()

    if not user:
        cursor.close()
        return jsonify({'message': 'User not found'}), 404

    user_id = user[0]

    cursor.execute('SELECT rounded_length, length_of_menses, predicted_ovulation FROM prediction WHERE id = %s', (user_id,))
    prediction = cursor.fetchone()
    cursor.close()

    if prediction:
        return jsonify({
            'rounded_length': prediction[0],
            'length_of_menses': prediction[1],
            'predicted_ovulation':prediction[2]
            })
    else:
        return jsonify({'message': 'No prediction found'}), 404

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
