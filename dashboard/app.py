import snowflake.connector
import streamlit as st

st.set_page_config(
    page_title="NYC Taxi Dashboard",
    layout="wide",
)

st.title("NYC Taxi Analytics Dashboard")

st.write(
    "Dashboard interactif basé sur les données NYC Yellow Taxi 2025 "
    "transformées avec Snowflake et dbt."
)


@st.cache_resource
def get_snowflake_connection():
    """Create and cache the Snowflake connection."""
    return snowflake.connector.connect(
        account=st.secrets["snowflake"]["account"],
        user=st.secrets["snowflake"]["user"],
        password=st.secrets["snowflake"]["password"],
        role=st.secrets["snowflake"]["role"],
        warehouse=st.secrets["snowflake"]["warehouse"],
        database=st.secrets["snowflake"]["database"],
        schema=st.secrets["snowflake"]["schema"],
    )


connection = get_snowflake_connection()

query = """
SELECT
    SUM(TOTAL_TRIPS) AS TOTAL_TRIPS,
    SUM(TOTAL_REVENUE) AS TOTAL_REVENUE,
    SUM(AVG_TRIP_DISTANCE * TOTAL_TRIPS) / SUM(TOTAL_TRIPS)
        AS AVG_TRIP_DISTANCE,
    SUM(AVG_TRIP_DURATION_MINUTES * TOTAL_TRIPS) / SUM(TOTAL_TRIPS)
        AS AVG_TRIP_DURATION_MINUTES
FROM FINAL.DAILY_SUMMARY
"""

cursor = connection.cursor()
cursor.execute(query)

result = cursor.fetchone()

cursor.close()

total_trips = result[0]
total_revenue = result[1]
avg_distance = result[2]
avg_duration = result[3]

col1, col2, col3, col4 = st.columns(4)

with col1:
    st.metric(
        label="Nombre total de trajets",
        value=f"{total_trips:,.0f}".replace(",", " "),
    )

with col2:
    st.metric(
        label="Chiffre d'affaires total",
        value=f"${total_revenue:,.0f}",
    )

with col3:
    st.metric(
        label="Distance moyenne",
        value=f"{avg_distance:.2f} miles",
    )

with col4:
    st.metric(
        label="Durée moyenne",
        value=f"{avg_duration:.2f} min",
    )

    st.subheader("Évolution quotidienne du nombre de trajets")

daily_query = """
SELECT
    PICKUP_DATE,
    TOTAL_TRIPS
FROM FINAL.DAILY_SUMMARY
ORDER BY PICKUP_DATE
"""

daily_cursor = connection.cursor()
daily_cursor.execute(daily_query)

daily_data = daily_cursor.fetchall()

daily_cursor.close()

daily_df = {
    "Date": [row[0] for row in daily_data],
    "Nombre de trajets": [row[1] for row in daily_data],
}

st.line_chart(
    daily_df,
    x="Date",
    y="Nombre de trajets",
)

day_type = st.selectbox(
    "Type de jour",
    ["Tous", "WEEKDAY", "WEEKEND"],
)
st.subheader("Nombre de trajets par heure")

if day_type == "Tous":
    hourly_query = """
    SELECT
        PICKUP_HOUR,
        SUM(TOTAL_TRIPS) AS TOTAL_TRIPS
    FROM FINAL.HOURLY_PATTERNS
    GROUP BY PICKUP_HOUR
    ORDER BY PICKUP_HOUR
    """

    hourly_cursor = connection.cursor()
    hourly_cursor.execute(hourly_query)

else:
    hourly_query = """
    SELECT
        PICKUP_HOUR,
        SUM(TOTAL_TRIPS) AS TOTAL_TRIPS
    FROM FINAL.HOURLY_PATTERNS
    WHERE DAY_TYPE = %s
    GROUP BY PICKUP_HOUR
    ORDER BY PICKUP_HOUR
    """

    hourly_cursor = connection.cursor()
    hourly_cursor.execute(hourly_query, (day_type,))

hourly_data = hourly_cursor.fetchall()

hourly_cursor.close()

hourly_df = {
    "Heure": [row[0] for row in hourly_data],
    "Nombre de trajets": [row[1] for row in hourly_data],
}

st.bar_chart(
    hourly_df,
    x="Heure",
    y="Nombre de trajets",
)

st.subheader("Top 10 des zones de prise en charge")

zone_query = """
SELECT
    PULOCATIONID,
    TOTAL_TRIPS
FROM FINAL.ZONE_ANALYSIS
ORDER BY TOTAL_TRIPS DESC
LIMIT 10
"""

zone_cursor = connection.cursor()
zone_cursor.execute(zone_query)

zone_data = zone_cursor.fetchall()

zone_cursor.close()

zone_df = {
    "Zone": [str(row[0]) for row in zone_data],
    "Nombre de trajets": [row[1] for row in zone_data],
}

st.bar_chart(
    zone_df,
    x="Zone",
    y="Nombre de trajets",
)